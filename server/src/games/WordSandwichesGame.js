const fs = require("fs");
const path = require("path");
const BaseGame = require("./BaseGame");

const TOTAL_DURATION_MS = 60000;
const SEGMENT_DURATION_MS = 20000;
const RESULT_DURATION_MS = 8000;
const SEGMENT_COUNT = TOTAL_DURATION_MS / SEGMENT_DURATION_MS;

const WORD_SANDWICH_COMBOS = [
  'ati', 'tio', 'nes', 'ter', 'ica', 'abl', 'eri', 'ent',
  'all', 'ali', 'oni', 'nte', 'nti', 'sti', 'ver', 'rat',
  'per', 'ing', 'ene', 'oph', 'ero', 'lit', 'lat', 'tic',
  'tra', 'ato', 'iti', 'ari', 'nde', 'era', 'ist', 'tin',
  'olo', 'lin', 'ran', 'men', 'ili', 'mat', 'ona', 'rop',
  'ate', 'the', 'ion', 'log', 'les', 'tri', 'tro', 'ste',
  'tiv', 'ast', 'ine', 'ani', 'rin', 'ect', 'ant', 'ina',
  'ere', 'ula', 'cti', 'res', 'gra', 'emi', 'ori', 'nat',
  'nis', 'rap', 'str', 'ria', 'ida', 'phi', 'pho', 'rac',
  'cal', 'ome', 'ost', 'len', 'ell', 'ace', 'ric', 'der',
  'chi', 'nta', 'ngl', 'erm', 'eli', 'rou', 'tor', 'min',
  'oli', 'her', 'ers', 'est', 'oma', 'ini', 'tom', 'cul',
  'tat', 'lli', 'con', 'ous'
];

function shuffle(values) {
  const copy = [...values];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

function normalizeWord(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z]/g, "");
}

function analyzeWordForCombo(word, combo) {
  let index = word.indexOf(combo);
  while (index !== -1) {
    const leftCount = index;
    const rightCount = word.length - (index + combo.length);
    if (leftCount > 0 && rightCount > 0) {
      return {
        isValid: true,
        isSymmetric: leftCount === rightCount
      };
    }
    index = word.indexOf(combo, index + 1);
  }

  return {
    isValid: false,
    isSymmetric: false
  };
}

function loadDictionaryWords() {
  const dictionaryPath = path.join(__dirname, "..", "..", "dictionary.txt");
  const raw = fs.readFileSync(dictionaryPath, "utf8");
  return raw
    .split(/\r?\n/)
    .map((line) => normalizeWord(line))
    .filter(Boolean);
}

function buildDictionaryIndex(words, combos) {
  const comboMap = new Map();
  for (const combo of combos) {
    comboMap.set(combo, new Map());
  }

  for (const word of words) {
    for (const combo of combos) {
      const analysis = analyzeWordForCombo(word, combo);
      if (!analysis.isValid) continue;
      comboMap.get(combo).set(word, analysis);
    }
  }

  return comboMap;
}

const DICTIONARY_WORDS = loadDictionaryWords();
const DICTIONARY_INDEX = buildDictionaryIndex(DICTIONARY_WORDS, WORD_SANDWICH_COMBOS);
const AVAILABLE_COMBOS = WORD_SANDWICH_COMBOS.filter((combo) => DICTIONARY_INDEX.get(combo)?.size > 0);

class WordSandwichesGame extends BaseGame {
  constructor(context) {
    super(context);
    this.state = {
      startedAt: 0,
      endsAt: 0,
      comboSequence: [],
      comboIndex: 0,
      currentCombo: "",
      segmentEndsAt: 0,
      playerStats: {}
    };
  }

  start() {
    const now = Date.now();
    this.state.startedAt = now;
    this.state.endsAt = now + TOTAL_DURATION_MS;
    this.state.comboSequence = shuffle(AVAILABLE_COMBOS).slice(0, SEGMENT_COUNT);
    this.state.comboIndex = 0;
    this.state.currentCombo = this.state.comboSequence[0] || AVAILABLE_COMBOS[0] || "and";
    this.state.segmentEndsAt = now + SEGMENT_DURATION_MS;
    this.state.playerStats = {};

    for (const player of this.getPlayers()) {
      this.ensurePlayerStats(player.id);
    }

    this.setPhase("word_sandwiches_round");
    this.scheduleSegments();
    this.emitRoomState();
  }

  onPlayerJoined(player) {
    this.ensurePlayerStats(player.id);
    this.emitRoomState();
  }

  onPlayerLeft() {
    this.emitRoomState();
  }

  onPlayerIdChanged(previousId, nextId) {
    if (!this.state.playerStats[previousId]) {
      this.ensurePlayerStats(nextId);
      return;
    }

    this.state.playerStats[nextId] = this.state.playerStats[previousId];
    delete this.state.playerStats[previousId];
  }

  ensurePlayerStats(playerId) {
    if (this.state.playerStats[playerId]) return this.state.playerStats[playerId];

    this.state.playerStats[playerId] = {
      acceptedWords: [],
      acceptedWordMap: {},
      wordCount: 0,
      symmetryBonuses: 0,
      score: 0
    };

    return this.state.playerStats[playerId];
  }

  scheduleSegments() {
    for (let i = 1; i < SEGMENT_COUNT; i += 1) {
      this.schedule(`word-sandwiches-segment-${i}`, i * SEGMENT_DURATION_MS, () => {
        if (this.room.phase !== "word_sandwiches_round") return;
        this.state.comboIndex = i;
        this.state.currentCombo = this.state.comboSequence[i] || this.state.currentCombo;
        this.state.segmentEndsAt = Math.min(
          this.state.startedAt + ((i + 1) * SEGMENT_DURATION_MS),
          this.state.endsAt
        );
        this.emitRoomState();
      });
    }

    this.schedule("word-sandwiches-finish", TOTAL_DURATION_MS, () => {
      this.finishGame();
    });
  }

  finishGame() {
    this.setPhase("word_sandwiches_results");
    this.state.segmentEndsAt = 0;
    this.emitRoomState();

    this.schedule("word-sandwiches-return-to-vote", RESULT_DURATION_MS, () => {
      if (this.room.phase === "word_sandwiches_results") {
        this.manager.startGameVote(this.room.code);
      }
    });
  }

  handleAction(playerId, action, payload, ack) {
    if (action !== "submit_word") {
      this.acknowledge(ack, { ok: false, error: "Unknown Word Sandwiches action" });
      return;
    }

    if (this.room.phase !== "word_sandwiches_round") {
      this.acknowledge(ack, { ok: false, error: "Word Sandwiches is not active" });
      return;
    }

    if (!this.hasPlayer(playerId)) {
      this.acknowledge(ack, { ok: false, error: "Player is not in this room" });
      return;
    }

    const stats = this.ensurePlayerStats(playerId);
    const word = normalizeWord(payload?.word);
    const combo = this.state.currentCombo;

    if (word.length < 5) {
      this.acknowledge(ack, { ok: false, error: "Word must be at least 5 letters long" });
      return;
    }

    if (stats.acceptedWordMap[word]) {
      this.acknowledge(ack, { ok: false, error: "You already found that word" });
      return;
    }

    const comboEntries = DICTIONARY_INDEX.get(combo);
    const analysis = comboEntries?.get(word);
    if (!analysis?.isValid) {
      this.acknowledge(ack, { ok: false, error: `Word must contain ${combo.toUpperCase()} with letters on both sides` });
      return;
    }

    stats.acceptedWordMap[word] = true;
    stats.acceptedWords.unshift({
      value: word,
      combo,
      isSymmetric: analysis.isSymmetric,
      submittedAt: Date.now()
    });
    stats.wordCount += 1;
    if (analysis.isSymmetric) {
      stats.symmetryBonuses += 1;
    }
    stats.score = stats.wordCount + stats.symmetryBonuses;

    this.emitRoomState();
    this.acknowledge(ack, {
      ok: true,
      word,
      isSymmetric: analysis.isSymmetric,
      score: stats.score,
      wordCount: stats.wordCount,
      symmetryBonuses: stats.symmetryBonuses
    });
  }

  buildLeaderboard() {
    return this.getPlayers()
      .map((player) => {
        const stats = this.ensurePlayerStats(player.id);
        return {
          id: player.id,
          name: player.name,
          character: player.character,
          wordCount: stats.wordCount,
          symmetryBonuses: stats.symmetryBonuses,
          score: stats.score
        };
      })
      .sort((left, right) => {
        if (right.score !== left.score) return right.score - left.score;
        if (right.wordCount !== left.wordCount) return right.wordCount - left.wordCount;
        if (right.symmetryBonuses !== left.symmetryBonuses) return right.symmetryBonuses - left.symmetryBonuses;
        return left.name.localeCompare(right.name);
      });
  }

  getPlayerStats(playerId) {
    if (!playerId) return null;
    return this.ensurePlayerStats(playerId);
  }

  getPublicState() {
    return {
      currentCombo: this.state.currentCombo,
      comboIndex: this.state.comboIndex,
      comboSequence: this.state.comboSequence,
      segmentEndsAt: this.state.segmentEndsAt,
      gameEndsAt: this.state.endsAt,
      leaderboard: this.buildLeaderboard()
    };
  }

  getTvView() {
    const leaderboard = this.buildLeaderboard();
    const maxScore = leaderboard.length > 0 ? Math.max(...leaderboard.map((entry) => entry.score), 1) : 1;
    const activeRound = this.room.phase === "word_sandwiches_round";

    return {
      layout: activeRound ? "word_sandwiches" : "word_sandwiches_results",
      title: "Word Sandwiches",
      subtitle: activeRound
        ? `Round ${this.state.comboIndex + 1} of ${SEGMENT_COUNT} · New letters every 20 seconds`
        : "Final standings",
      description: activeRound
        ? "Find words that contain the letters with at least one letter on both sides. Balanced words earn a symmetry bonus."
        : "Returning to minigame voting shortly.",
      letters: String(this.state.currentCombo || "").toUpperCase(),
      segmentEndsAt: activeRound ? this.state.segmentEndsAt : 0,
      segmentDurationMs: activeRound ? SEGMENT_DURATION_MS : 0,
      maxScore,
      cards: leaderboard.map((entry, index) => ({
        title: entry.name,
        footer: `${entry.wordCount} word${entry.wordCount === 1 ? "" : "s"}`,
        rank: index + 1,
        score: entry.score,
        character: entry.character,
        symmetryBonuses: entry.symmetryBonuses,
        barRatio: entry.score / maxScore
      }))
    };
  }

  getControllerView(playerId) {
    const stats = this.getPlayerStats(playerId) || {
      acceptedWords: [],
      wordCount: 0,
      symmetryBonuses: 0,
      score: 0
    };
    const leaderboard = this.buildLeaderboard();
    const activeRound = this.room.phase === "word_sandwiches_round";

    return {
      layout: "word_sandwiches",
      title: "Word Sandwiches",
      details: activeRound
        ? `Submit words containing ${String(this.state.currentCombo || "").toUpperCase()} with letters on both sides.`
        : "Round complete.",
      letters: String(this.state.currentCombo || "").toUpperCase(),
      isFinal: !activeRound,
      segmentNumber: Math.min(this.state.comboIndex + 1, SEGMENT_COUNT),
      segmentTotal: SEGMENT_COUNT,
      segmentEndsAt: activeRound ? this.state.segmentEndsAt : 0,
      gameEndsAt: this.state.endsAt,
      myWordCount: stats.wordCount,
      mySymmetryBonuses: stats.symmetryBonuses,
      myScore: stats.score,
      myWords: stats.acceptedWords.slice(0, 8),
      leaderboard: leaderboard.map((entry, index) => ({
        id: entry.id,
        label: entry.name,
        character: entry.character,
        rank: index + 1,
        wordCount: entry.wordCount,
        symmetryBonuses: entry.symmetryBonuses,
        score: entry.score
      }))
    };
  }
}

WordSandwichesGame.meta = {
  id: "word-sandwiches",
  name: "Word Sandwiches",
  description: "Build words that hide the three-letter center. Balanced sandwiches earn bonus points."
};

module.exports = WordSandwichesGame;
