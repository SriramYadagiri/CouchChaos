const gameCatalog = require("./config/gameCatalog");
const RECONNECT_GRACE_MS = 60000;
const MAX_PLAYERS = 12;

const CHARACTER_SLUGS = [
  "character_01", "character_02", "character_03", "character_04",
  "character_05", "character_06", "character_07", "character_08",
  "character_09", "character_10", "character_11", "character_12"
];

function normalizeName(name) {
  return String(name || "")
    .trim()
    .replace(/\s+/g, " ")
    .toLowerCase();
}

function formatDisplayName(name) {
  const normalized = normalizeName(name);
  if (!normalized) return "";

  return normalized
    .split(" ")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

class GameManager {
  constructor({ io, gameRegistry }) {
    this.io = io;
    this.gameRegistry = gameRegistry;
    this.rooms = {};
  }

  createRoom(code) {
    this.rooms[code] = {
      code,
      players: [],
      phase: "lobby",
      games: this.buildGameCatalog(),
      gameVotes: {},
      selectedGame: null,
      activeGame: null,
      selectionTimer: null
    };

    return this.rooms[code];
  }

  getRoom(code) {
    return this.rooms[code] || null;
  }

  buildGameCatalog() {
    return gameCatalog.map((game) => ({
      ...game,
      votes: 0
    }));
  }

  getUsedCharacters(room) {
    return room.players.map((p) => p.character).filter(Boolean);
  }

  assignCharacter(room) {
    const used = new Set(this.getUsedCharacters(room));
    const available = CHARACTER_SLUGS.filter((c) => !used.has(c));
    if (available.length === 0) return null;
    return available[Math.floor(Math.random() * available.length)];
  }

  joinRoom(code, socket, name, clientId) {
    const room = this.getRoom(code);
    if (!room) {
      return { ok: false, error: "Invalid room" };
    }

    const normalizedName = normalizeName(name);
    const displayName = formatDisplayName(name);

    if (!normalizedName) {
      return { ok: false, error: "Enter a valid name" };
    }

    if (!clientId) {
      return { ok: false, error: "Missing client ID" };
    }

    const existingPlayer = room.players.find((player) => player.clientId === clientId);
    const duplicateNamePlayer = room.players.find((player) => (
      player.normalizedName === normalizedName && player.clientId !== clientId
    ));

    if (duplicateNamePlayer) {
      return { ok: false, error: "That name is already taken" };
    }

    socket.join(code);

    if (existingPlayer) {
      const previousId = existingPlayer.id;
      this.clearDisconnectTimer(existingPlayer);
      existingPlayer.id = socket.id;
      existingPlayer.isConnected = true;
      existingPlayer.disconnectedAt = null;
      existingPlayer.name = displayName;
      existingPlayer.normalizedName = normalizedName;

      if (previousId && room.gameVotes[previousId]) {
        room.gameVotes[socket.id] = room.gameVotes[previousId];
        delete room.gameVotes[previousId];
      }

      if (room.activeGame && previousId && previousId !== socket.id) {
        room.activeGame.onPlayerIdChanged(previousId, socket.id);
      }

      this.emitPlayersUpdate(code);
      this.emitRoomState(code);
      return { ok: true, player: existingPlayer, reconnected: true };
    }

    // Check player cap for new (non-reconnecting) players
    const connectedCount = room.players.filter((p) => p.isConnected).length;
    if (connectedCount >= MAX_PLAYERS) {
      return { ok: false, error: "This room is full (max 12 players)" };
    }

    const character = this.assignCharacter(room);
    if (!character) {
      return { ok: false, error: "No characters available" };
    }

    const player = {
      id: socket.id,
      clientId,
      name: displayName,
      normalizedName,
      character,
      isConnected: true,
      disconnectedAt: null,
      disconnectTimer: null
    };

    room.players.push(player);

    if (room.activeGame) {
      room.activeGame.onPlayerJoined(player);
    }

    this.emitPlayersUpdate(code);
    this.emitRoomState(code);
    return { ok: true, player, reconnected: false };
  }

  removeSocket(socketId) {
    for (const room of Object.values(this.rooms)) {
      const player = room.players.find((entry) => entry.id === socketId);
      if (!player) continue;

      player.isConnected = false;
      player.disconnectedAt = Date.now();
      this.scheduleDisconnectRemoval(room.code, player);
      this.emitPlayersUpdate(room.code);
      this.emitRoomState(room.code);
      break;
    }
  }

  startGameVote(code) {
    const room = this.getRoom(code);
    if (!room) return null;

    if (room.selectionTimer) {
      clearTimeout(room.selectionTimer);
      room.selectionTimer = null;
    }

    if (room.activeGame) {
      room.activeGame.cleanup();
    }

    room.activeGame = null;
    room.phase = "game_select";
    room.games = this.buildGameCatalog();
    room.gameVotes = {};
    room.selectedGame = null;

    this.emitRoomState(code);
    return this.buildPublicRoomState(room);
  }

  voteForGame(code, playerId, gameId) {
    const room = this.getRoom(code);
    if (!room) return { ok: false, error: "Invalid room" };
    if (room.phase !== "game_select") return { ok: false, error: "Voting is not active" };
    if (!room.players.some((player) => player.id === playerId)) {
      return { ok: false, error: "Player is not in this room" };
    }

    const selectedGame = room.games.find((game) => game.id === gameId);
    if (!selectedGame) return { ok: false, error: "Invalid game" };
    if (room.gameVotes[playerId]) return { ok: false, error: "Vote already submitted" };

    room.gameVotes[playerId] = gameId;
    this.maybeFinalizeGameVote(code);
    return { ok: true, gameId };
  }

  routeGameAction(code, playerId, action, payload, ack) {
    const room = this.getRoom(code);
    if (!room) {
      if (typeof ack === "function") ack({ ok: false, error: "Invalid room" });
      return;
    }

    if (!room.activeGame) {
      if (typeof ack === "function") ack({ ok: false, error: "No active game" });
      return;
    }

    room.activeGame.handleAction(playerId, action, payload, ack);
  }

  maybeFinalizeGameVote(code) {
    const room = this.getRoom(code);
    if (!room || room.phase !== "game_select") return;
    if (room.players.length === 0) return;

    const voteCount = Object.keys(room.gameVotes).length;

    this.tallyVotes(room);

    if (voteCount < room.players.length) {
      this.emitRoomState(code);
      return;
    }

    let highestVotes = -1;
    let tiedGames = [];

    for (const game of room.games) {
      if (game.votes > highestVotes) {
        highestVotes = game.votes;
        tiedGames = [game];
      } else if (game.votes === highestVotes) {
        tiedGames.push(game);
      }
    }

    if (tiedGames.length === 0) return;

    const winner = tiedGames[Math.floor(Math.random() * tiedGames.length)];
    room.selectedGame = {
      id: winner.id,
      name: winner.name,
      description: winner.description
    };
    room.phase = "game_selected";

    this.emitRoomState(code);

    room.selectionTimer = setTimeout(() => {
      room.selectionTimer = null;
      this.startSelectedGame(code, winner.id);
    }, 1200);
  }

  startSelectedGame(code, gameId) {
    const room = this.getRoom(code);
    if (!room) return;

    const GameClass = this.gameRegistry[gameId];
    if (!GameClass) {
      room.phase = "lobby";
      this.emitRoomState(code);
      return;
    }

    if (room.activeGame) {
      room.activeGame.cleanup();
    }

    room.activeGame = new GameClass({
      io: this.io,
      manager: this,
      room,
      meta: GameClass.meta
    });

    room.activeGame.start();
  }

  tallyVotes(room) {
    const voteCounts = {};

    for (const game of room.games) {
      voteCounts[game.id] = 0;
    }

    for (const gameId of Object.values(room.gameVotes)) {
      if (voteCounts[gameId] !== undefined) {
        voteCounts[gameId] += 1;
      }
    }

    room.games = room.games.map((game) => ({
      ...game,
      votes: voteCounts[game.id] || 0
    }));
  }

  // Returns a map of playerId -> character slug for all players in a room
  getPlayerCharacterMap(room) {
    const map = {};
    for (const player of room.players) {
      if (player.character) map[player.id] = player.character;
    }
    return map;
  }

  emitPlayersUpdate(code) {
    const room = this.getRoom(code);
    if (!room) return;

    this.io.to(code).emit("players_update", room.players.map((player) => ({
      id: player.id,
      name: player.name,
      character: player.character,
      isConnected: player.isConnected
    })));
  }

  emitRoomState(code) {
    const room = this.getRoom(code);
    if (!room) return;

    for (const player of room.players.filter((entry) => entry.isConnected)) {
      const controllerState = this.buildControllerStateForPlayer(room, player.id);
      const privateState = room.activeGame
        ? room.activeGame.getPrivateState(player.id)
        : { gameId: null };
      this.io.to(player.id).emit("game_state", controllerState);
      this.io.to(player.id).emit("private_state", privateState);
    }
  }

  buildPublicRoomState(room) {
    const activeGame = room.activeGame;
    const publicGameState = activeGame ? activeGame.getPublicState() : {};
    const tvView = activeGame
      ? activeGame.getTvView()
      : this.buildManagerTvView(room);
    const controllerView = activeGame
      ? activeGame.getControllerView(null)
      : this.buildManagerControllerView(room);

    return {
      phase: room.phase,
      players: room.players.map((player) => ({
        id: player.id,
        name: player.name,
        character: player.character,
        isConnected: player.isConnected
      })),
      playerCharacters: this.getPlayerCharacterMap(room),
      games: room.games,
      selectedGame: room.selectedGame,
      activeGameId: activeGame?.id || null,
      tvView,
      controllerView,
      ...publicGameState
    };
  }

  buildControllerStateForPlayer(room, playerId) {
    const publicState = this.buildPublicRoomState(room);
    if (room.activeGame) {
      publicState.controllerView = room.activeGame.getControllerView(playerId);
    }
    return publicState;
  }

  buildManagerTvView(room) {
    const connectedCount = room.players.filter((player) => player.isConnected).length;

    if (room.phase === "game_select") {
      return {
        layout: "game_vote",
        title: "Vote For The Next Minigame",
        subtitle: "Players vote on their phones. Move focus to preview a game.",
        description: "",
        cards: room.games.map((game) => ({
          title: game.name,
          description: game.description,
          footer: `${game.votes} vote(s)`
        }))
      };
    }

    if (room.phase === "game_selected") {
      return {
        layout: "game_vote",
        title: "Vote For The Next Minigame",
        subtitle: room.selectedGame ? `Selected minigame: ${room.selectedGame.name}` : "Game selected",
        description: room.selectedGame?.description || "",
        cards: room.games.map((game) => ({
          title: game.name,
          description: game.description,
          footer: `${game.votes} vote(s)`
        }))
      };
    }

    return {
      layout: "message",
      title: "Vote For The Next Minigame",
      subtitle: "Waiting for the next round.",
      description: connectedCount > 0
        ? `${connectedCount} player(s) connected.`
        : "Create a room and have players join."
    };
  }

  buildManagerControllerView(room) {
    if (room.phase === "game_select") {
      return {
        layout: "game_vote",
        title: "Vote for the next game",
        details: "Choose a minigame on your phone. The Roku shows the preview.",
        options: room.games.map((game) => ({
          id: game.id,
          label: game.name,
          description: game.description,
          meta: `${game.votes} vote(s)`
        }))
      };
    }

    if (room.phase === "game_selected") {
      return {
        layout: "message",
        title: "Game selected",
        details: room.selectedGame
          ? `${room.selectedGame.name} won the vote.`
          : "Waiting for the TV."
      };
    }

    return {
      layout: "message",
      title: "Look at the TV",
      details: "Waiting for the next prompt."
    };
  }

  scheduleDisconnectRemoval(code, player) {
    this.clearDisconnectTimer(player);
    player.disconnectTimer = setTimeout(() => {
      player.disconnectTimer = null;
      this.finalizePlayerRemoval(code, player.clientId);
    }, RECONNECT_GRACE_MS);
  }

  clearDisconnectTimer(player) {
    if (!player?.disconnectTimer) return;
    clearTimeout(player.disconnectTimer);
    player.disconnectTimer = null;
  }

  finalizePlayerRemoval(code, clientId) {
    const room = this.getRoom(code);
    if (!room) return;

    const player = room.players.find((entry) => entry.clientId === clientId);
    if (!player || player.isConnected) return;

    room.players = room.players.filter((entry) => entry.clientId !== clientId);
    delete room.gameVotes[player.id];

    if (room.activeGame) {
      room.activeGame.onPlayerLeft(player.id);
    }

    if (room.phase === "game_select") {
      this.tallyVotes(room);
      this.maybeFinalizeGameVote(room.code);
    }

    this.emitPlayersUpdate(room.code);
    this.emitRoomState(room.code);
  }
}

module.exports = GameManager;