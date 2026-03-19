const gameCatalog = require("./config/gameCatalog");

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

  joinRoom(code, socket, name) {
    const room = this.getRoom(code);
    if (!room) {
      return { ok: false, error: "Invalid room" };
    }

    const existingPlayer = room.players.find((player) => player.name === name);
    socket.join(code);

    if (existingPlayer) {
      const previousId = existingPlayer.id;
      existingPlayer.id = socket.id;

      if (room.gameVotes[previousId]) {
        room.gameVotes[socket.id] = room.gameVotes[previousId];
        delete room.gameVotes[previousId];
      }

      if (room.activeGame) {
        room.activeGame.onPlayerIdChanged(previousId, socket.id);
      }

      this.emitPlayersUpdate(code);
      this.emitRoomState(code);
      return { ok: true, player: existingPlayer, reconnected: true };
    }

    const player = {
      id: socket.id,
      name
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

      room.players = room.players.filter((entry) => entry.id !== socketId);
      delete room.gameVotes[socketId];

      if (room.activeGame) {
        room.activeGame.onPlayerLeft(socketId);
      }

      if (room.phase === "game_select") {
        this.tallyVotes(room);
        this.maybeFinalizeGameVote(room.code);
      }

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

  emitPlayersUpdate(code) {
    const room = this.getRoom(code);
    if (!room) return;

    this.io.to(code).emit("players_update", room.players.map((player) => ({
      id: player.id,
      name: player.name
    })));
  }

  emitRoomState(code) {
    const room = this.getRoom(code);
    if (!room) return;

    for (const player of room.players) {
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
        name: player.name
      })),
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
      description: room.players.length > 0
        ? `${room.players.length} player(s) connected.`
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
}

module.exports = GameManager;
