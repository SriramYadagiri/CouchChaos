class BaseGame {
  constructor({ io, manager, room, meta }) {
    this.io = io;
    this.manager = manager;
    this.room = room;
    this.meta = meta;
    this.timers = new Map();
  }

  get id() {
    return this.meta.id;
  }

  getPlayers() {
    return this.room.players || [];
  }

  getPlayer(playerId) {
    return this.getPlayers().find((player) => player.id === playerId) || null;
  }

  hasPlayer(playerId) {
    return Boolean(this.getPlayer(playerId));
  }

  setPhase(phase) {
    this.room.phase = phase;
  }

  emitRoomState() {
    this.manager.emitRoomState(this.room.code);
  }

  schedule(key, delayMs, callback) {
    this.clearTimer(key);
    const timer = setTimeout(() => {
      this.timers.delete(key);
      callback();
    }, delayMs);
    this.timers.set(key, timer);
  }

  clearTimer(key) {
    const timer = this.timers.get(key);
    if (!timer) return;
    clearTimeout(timer);
    this.timers.delete(key);
  }

  cleanup() {
    for (const timer of this.timers.values()) {
      clearTimeout(timer);
    }
    this.timers.clear();
  }

  acknowledge(ack, payload) {
    if (typeof ack === "function") ack(payload);
  }

  onPlayerJoined() {}

  onPlayerLeft() {}

  onPlayerIdChanged() {}

  start() {
    throw new Error(`${this.constructor.name} must implement start()`);
  }

  handleAction(playerId, action, payload, ack) {
    this.acknowledge(ack, { ok: false, error: `Unsupported action: ${action}` });
  }

  getPublicState() {
    return {};
  }

  getPrivateState() {
    return { gameId: this.id };
  }

  getTvView() {
    return null;
  }

  getControllerView() {
    return null;
  }
}

module.exports = BaseGame;
