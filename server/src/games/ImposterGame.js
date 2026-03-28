const BaseGame = require("./BaseGame");
const { pickRandom, shuffle } = require("../utils/random");

const WORD_BANK = [
  "Volcano",
  "Pineapple",
  "Backpack",
  "Thunder",
  "Blanket",
  "Skateboard",
  "Popcorn",
  "Treasure",
  "Spaceship",
  "Campfire"
];

class ImposterGame extends BaseGame {
  constructor(context) {
    super(context);
    this.state = {
      word: null,
      imposterId: null,
      turnOrder: [],
      currentTurnIndex: 0,
      roundNumber: 1,
      votes: {},
      eliminatedIds: [],
      lastRoundSummary: ""
    };
  }

  start() {
    const players = this.getPlayers();

    if (players.length < 3) {
      this.setPhase("imposter_waiting");
      this.state.lastRoundSummary = "Imposter needs at least 3 players.";
      this.emitRoomState();
      return;
    }

    this.state.word = pickRandom(WORD_BANK);
    this.state.imposterId = pickRandom(players)?.id || null;
    this.state.turnOrder = shuffle(players.map((player) => player.id));
    this.state.currentTurnIndex = 0;
    this.state.roundNumber = 1;
    this.state.votes = {};
    this.state.eliminatedIds = [];
    this.state.lastRoundSummary = `${this.getCurrentSpeakerName()} gives the first hint. Anyone can end the clue round and start the vote.`;

    this.setPhase("imposter_round");
    this.emitRoomState();
  }

  onPlayerJoined() {
    if (this.room.phase === "imposter_waiting" && this.getPlayers().length >= 3) {
      this.start();
    } else {
      this.emitRoomState();
    }
  }

  onPlayerIdChanged(previousId, nextId) {
    if (this.state.imposterId === previousId) {
      this.state.imposterId = nextId;
    }

    this.state.turnOrder = this.state.turnOrder.map((playerId) => (
      playerId === previousId ? nextId : playerId
    ));

    if (this.state.votes[previousId]) {
      this.state.votes[nextId] = this.state.votes[previousId];
      delete this.state.votes[previousId];
    }

    for (const voterId of Object.keys(this.state.votes)) {
      if (this.state.votes[voterId] === previousId) {
        this.state.votes[voterId] = nextId;
      }
    }

    this.state.eliminatedIds = this.state.eliminatedIds.map((playerId) => (
      playerId === previousId ? nextId : playerId
    ));
  }

  onPlayerLeft(playerId) {
    this.state.turnOrder = this.state.turnOrder.filter((id) => id !== playerId);
    this.state.eliminatedIds = this.state.eliminatedIds.filter((id) => id !== playerId);
    delete this.state.votes[playerId];

    for (const voterId of Object.keys(this.state.votes)) {
      if (this.state.votes[voterId] === playerId) {
        delete this.state.votes[voterId];
      }
    }

    if (this.state.imposterId === playerId) {
      this.setPhase("imposter_result");
      this.state.lastRoundSummary = "The imposter disconnected. Normal players win.";
      this.emitRoomState();
      return;
    }

    if (this.getAlivePlayers().length <= 2 && this.room.phase !== "imposter_result") {
      this.setPhase("imposter_result");
      this.state.lastRoundSummary = "Only two players remain. The imposter wins.";
      this.emitRoomState();
      return;
    }

    if (this.room.phase === "imposter_voting") {
      this.maybeResolveVote();
    } else {
      this.ensureCurrentTurnIsAlive();
      this.emitRoomState();
    }
  }

  handleAction(playerId, action, payload, ack) {
    if (!this.hasPlayer(playerId)) {
      this.acknowledge(ack, { ok: false, error: "Player is not in this room" });
      return;
    }

    if (this.isEliminated(playerId) && this.room.phase !== "imposter_result") {
      this.acknowledge(ack, { ok: false, error: "Eliminated players cannot act" });
      return;
    }

    if (action === "advance_turn") {
      this.handleAdvanceTurn(playerId, ack);
      return;
    }

    if (action === "start_vote") {
      this.handleStartVote(ack);
      return;
    }

    if (action === "cast_vote") {
      this.handleCastVote(playerId, payload, ack);
      return;
    }

    this.acknowledge(ack, { ok: false, error: "Unknown imposter action" });
  }

  handleAdvanceTurn(playerId, ack) {
    if (this.room.phase !== "imposter_round") {
      this.acknowledge(ack, { ok: false, error: "It is not hint time" });
      return;
    }

    if (this.getCurrentSpeakerId() !== playerId) {
      this.acknowledge(ack, { ok: false, error: "Only the current speaker can pass the turn" });
      return;
    }

    this.advanceTurn();
    this.state.lastRoundSummary = `${this.getCurrentSpeakerName()} is up next. Keep giving clues or end the round and vote.`;
    this.emitRoomState();
    this.acknowledge(ack, { ok: true });
  }

  handleStartVote(ack) {
    if (this.room.phase !== "imposter_round") {
      this.acknowledge(ack, { ok: false, error: "Voting is not available right now" });
      return;
    }

    this.state.votes = {};
    this.state.lastRoundSummary = "The clue round has ended. Everyone is now voting for the imposter.";
    this.setPhase("imposter_voting");
    this.emitRoomState();
    this.acknowledge(ack, { ok: true });
  }

  handleCastVote(playerId, payload, ack) {
    if (this.room.phase !== "imposter_voting") {
      this.acknowledge(ack, { ok: false, error: "Voting is not active" });
      return;
    }

    const targetPlayerId = payload?.targetPlayerId;
    if (!targetPlayerId || !this.isAlive(targetPlayerId)) {
      this.acknowledge(ack, { ok: false, error: "Choose a valid player" });
      return;
    }

    if (this.state.votes[playerId]) {
      this.acknowledge(ack, { ok: false, error: "Vote already submitted" });
      return;
    }

    this.state.votes[playerId] = targetPlayerId;
    this.maybeResolveVote();
    this.acknowledge(ack, { ok: true });
  }

  maybeResolveVote() {
    const alivePlayers = this.getAlivePlayers();
    const allVoted = alivePlayers.every((player) => this.state.votes[player.id]);

    if (!allVoted) {
      this.emitRoomState();
      return;
    }

    const voteCounts = this.getVoteCounts();
    let majorityTargetId = null;
    let highestVotes = 0;

    for (const [targetId, count] of Object.entries(voteCounts)) {
      if (count > highestVotes) {
        highestVotes = count;
        majorityTargetId = targetId;
      }
    }

    const majorityNeeded = Math.floor(alivePlayers.length / 2) + 1;

    if (!majorityTargetId || highestVotes < majorityNeeded) {
      this.state.votes = {};
      this.setPhase("imposter_round");
      this.advanceTurn();
      this.state.lastRoundSummary = `No majority. No one was eliminated. ${this.getCurrentSpeakerName()} starts the next clue round.`;
      this.emitRoomState();
      return;
    }

    this.state.eliminatedIds.push(majorityTargetId);
    const eliminatedPlayer = this.getPlayer(majorityTargetId);

    if (majorityTargetId === this.state.imposterId) {
      this.setPhase("imposter_result");
      this.state.lastRoundSummary = `${eliminatedPlayer?.name || "The imposter"} was eliminated. Normal players win.`;
      this.emitRoomState();
      return;
    }

    if (this.getAlivePlayers().length <= 2) {
      this.setPhase("imposter_result");
      this.state.lastRoundSummary = `${eliminatedPlayer?.name || "A player"} was eliminated. Two players remain, so the imposter wins.`;
      this.emitRoomState();
      return;
    }

    this.state.votes = {};
    this.state.roundNumber += 1;
    this.setPhase("imposter_round");
    this.ensureCurrentTurnIsAlive();
    this.state.lastRoundSummary = `${eliminatedPlayer?.name || "A player"} was eliminated. ${this.getCurrentSpeakerName()} starts the next round.`;
    this.emitRoomState();
  }

  advanceTurn() {
    const aliveOrder = this.state.turnOrder.filter((playerId) => this.isAlive(playerId));
    if (aliveOrder.length === 0) return;

    const currentSpeakerId = this.getCurrentSpeakerId();
    const currentIndex = aliveOrder.indexOf(currentSpeakerId);
    const nextIndex = currentIndex >= 0
      ? (currentIndex + 1) % aliveOrder.length
      : 0;
    const nextSpeakerId = aliveOrder[nextIndex];

    this.state.currentTurnIndex = this.state.turnOrder.indexOf(nextSpeakerId);
  }

  ensureCurrentTurnIsAlive() {
    const currentSpeakerId = this.getCurrentSpeakerId();
    if (currentSpeakerId && this.isAlive(currentSpeakerId)) return;

    const nextAlivePlayer = this.state.turnOrder.find((playerId) => this.isAlive(playerId));
    this.state.currentTurnIndex = Math.max(0, this.state.turnOrder.indexOf(nextAlivePlayer));
  }

  getCurrentSpeakerId() {
    return this.state.turnOrder[this.state.currentTurnIndex] || null;
  }

  getCurrentSpeakerName() {
    return this.getPlayer(this.getCurrentSpeakerId())?.name || "Next player";
  }

  isEliminated(playerId) {
    return this.state.eliminatedIds.includes(playerId);
  }

  isAlive(playerId) {
    return this.hasPlayer(playerId) && !this.isEliminated(playerId);
  }

  getAlivePlayers() {
    return this.getPlayers().filter((player) => this.isAlive(player.id));
  }

  getVoteCounts() {
    const counts = {};

    for (const player of this.getAlivePlayers()) {
      counts[player.id] = 0;
    }

    for (const targetId of Object.values(this.state.votes)) {
      if (counts[targetId] !== undefined) {
        counts[targetId] += 1;
      }
    }

    return counts;
  }

  // Build a map of targetId -> array of voter characters
  getVotesByTarget() {
    const byTarget = {};
    for (const [voterId, targetId] of Object.entries(this.state.votes)) {
      if (!byTarget[targetId]) byTarget[targetId] = [];
      const voter = this.getPlayer(voterId);
      if (voter) byTarget[targetId].push(voter.character || null);
    }
    return byTarget;
  }

  getVoterNamesByTarget() {
    const byTarget = {};
    for (const [voterId, targetId] of Object.entries(this.state.votes)) {
      if (!byTarget[targetId]) byTarget[targetId] = [];
      const voter = this.getPlayer(voterId);
      if (voter) byTarget[targetId].push(voter.name);
    }
    return byTarget;
  }

  getPublicState() {
    const voteCounts = this.getVoteCounts();
    const votesByTarget = this.getVotesByTarget();
    const voterNamesByTarget = this.getVoterNamesByTarget();
    const alivePlayers = this.getAlivePlayers();

    return {
      roundNumber: this.state.roundNumber,
      currentSpeakerId: this.getCurrentSpeakerId(),
      currentSpeakerName: this.getCurrentSpeakerName(),
      votesCast: Object.keys(this.state.votes).length,
      aliveCount: alivePlayers.length,
      imposterName: this.getPlayer(this.state.imposterId)?.name || "The Imposter",
      alivePlayers: this.getPlayers().map((player) => ({
        id: player.id,
        name: player.name,
        character: player.character,
        isEliminated: this.isEliminated(player.id),
        isCurrentTurn: player.id === this.getCurrentSpeakerId(),
        voteCount: voteCounts[player.id] || 0,
        voterCharacters: votesByTarget[player.id] || [],
        voterNames: voterNamesByTarget[player.id] || []
      })),
      lastRoundSummary: this.state.lastRoundSummary
    };
  }

  getPrivateState(playerId) {
    const isImposter = playerId === this.state.imposterId;
    const isEliminated = this.isEliminated(playerId);

    if (this.room.phase === "imposter_waiting") {
      return {
        gameId: this.id,
        title: "Imposter",
        message: "Waiting for enough players to start."
      };
    }

    return {
      gameId: this.id,
      title: isImposter ? "You are the Imposter" : "Your secret word",
      message: isImposter ? "Blend in and avoid suspicion." : this.state.word,
      footer: isEliminated ? "You are eliminated. Keep watching the round." : "Keep this private.",
      isImposter,
      isEliminated
    };
  }

  getTvView() {
    const publicState = this.getPublicState();

    if (this.room.phase === "imposter_waiting") {
      return {
        layout: "message",
        title: "Imposter",
        subtitle: "Waiting for players",
        description: "At least 3 players are required to start."
      };
    }

    if (this.room.phase === "imposter_round") {
      return {
        layout: "player_grid",
        title: "Imposter",
        subtitle: `Round ${publicState.roundNumber} | ${publicState.currentSpeakerName}'s turn`,
        description: publicState.lastRoundSummary || "Players give clues out loud. Anyone can end the clue round and start the vote.",
        cards: publicState.alivePlayers.map((player) => ({
          title: player.name,
          description: player.isEliminated ? "Eliminated" : (player.isCurrentTurn ? "Current turn" : "Still in"),
          footer: player.isCurrentTurn ? "Speaking now" : (player.isEliminated ? "Out" : "Listening")
        }))
      };
    }

    if (this.room.phase === "imposter_voting") {
      return {
        layout: "player_grid",
        title: "Vote Out The Imposter",
        subtitle: `${publicState.votesCast}/${publicState.aliveCount} vote(s) locked`,
        description: "The clue round is over. The TV shows who each vote is landing on as the room decides who to eliminate.",
        cards: publicState.alivePlayers
          .filter((player) => !player.isEliminated)
          .map((player) => ({
            title: player.name,
            description: `${player.voteCount} vote(s)`,
            footer: player.voterNames.length > 0 ? `Voted by: ${player.voterNames.join(", ")}` : "Waiting for votes"
          }))
      };
    }

    if (this.room.phase === "imposter_result") {
      return {
        layout: "player_grid",
        title: "Imposter Result",
        subtitle: `The imposter was ${publicState.imposterName}`,
        description: this.state.lastRoundSummary,
        cards: this.getPlayers().map((player) => ({
          title: player.name,
          description: player.id === this.state.imposterId ? "Imposter" : "Crew",
          footer: this.isEliminated(player.id) ? "Eliminated" : "Survived"
        }))
      };
    }

    return null;
  }

  getControllerView(playerId) {
    const publicState = this.getPublicState();
    const hasVoted = Boolean(playerId && this.state.votes[playerId]);
    const isCurrentSpeaker = playerId ? publicState.currentSpeakerId === playerId : false;
    const myVoteTargetId = playerId ? this.state.votes[playerId] : null;

    if (this.room.phase === "imposter_waiting") {
      return {
        layout: "message",
        title: "Imposter",
        details: "Waiting for enough players to start."
      };
    }

    if (this.room.phase === "imposter_round") {
      return {
        layout: "imposter_round",
        title: "Imposter",
        details: publicState.lastRoundSummary || "Give one spoken hint, then pass the turn or end the clue round and vote.",
        canAdvanceTurn: isCurrentSpeaker,
        canStartVote: playerId ? !this.isEliminated(playerId) : false,
        players: publicState.alivePlayers,
        currentSpeakerId: publicState.currentSpeakerId
      };
    }

    if (this.room.phase === "imposter_voting") {
      return {
        layout: "player_vote",
        title: "Vote out the imposter",
        details: hasVoted ? "Vote locked in. Waiting for the others." : "Choose one player. Majority vote eliminates them.",
        myVoteTargetId,
        players: publicState.alivePlayers.filter((player) => !player.isEliminated).map((player) => ({
          id: player.id,
          label: player.name,
          character: player.character,
          value: `${player.voteCount} vote(s)`,
          voterCharacters: player.voterCharacters,
          disabled: hasVoted
        }))
      };
    }

    if (this.room.phase === "imposter_result") {
      return {
        layout: "leaderboard",
        title: "Game over",
        details: this.state.lastRoundSummary,
        items: this.getPlayers().map((player) => ({
          id: player.id,
          label: player.name,
          character: player.character,
          value: player.id === this.state.imposterId ? "Imposter" : "Crew"
        }))
      };
    }

    return null;
  }
}

ImposterGame.meta = {
  id: "imposter",
  name: "Imposter",
  description: "One player gets no word. Blend in, listen closely, then vote them out."
};

module.exports = ImposterGame;