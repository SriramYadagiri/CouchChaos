const fs = require("fs");
const path = require("path");
const BaseGame = require("./BaseGame");

const WORD_LENGTH = 5;
const MAX_ATTEMPTS = 6;
const ROUND_DURATION_MS = 45000;
const RESULT_DURATION_MS = 3000;
const FINAL_RESULTS_MS = 10000;
const TOTAL_ROUNDS = 3;

function normalizeWord(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z]/g, "");
}

function shuffle(values) {
  const copy = [...values];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

function buildLetterCounts(target) {
  const counts = {};
  for (const letter of target) {
    counts[letter] = (counts[letter] || 0) + 1;
  }
  return counts;
}

function scoreGuess(guess, target) {
  const feedback = Array.from({ length: target.length }, () => "absent");
  const remaining = buildLetterCounts(target);

  for (let i = 0; i < guess.length; i += 1) {
    if (guess[i] === target[i]) {
      feedback[i] = "correct";
      remaining[guess[i]] -= 1;
    }
  }

  for (let i = 0; i < guess.length; i += 1) {
    if (feedback[i] === "correct") continue;
    const letter = guess[i];
    if ((remaining[letter] || 0) > 0) {
      feedback[i] = "present";
      remaining[letter] -= 1;
    }
  }

  return feedback;
}

function loadWordList() {
  const dictionaryPath = path.join(__dirname, "..", "..", "dictionary.txt");
  let words = [];

  try {
    const raw = fs.readFileSync(dictionaryPath, "utf8");
    words = raw
      .split(/\r?\n/)
      .map(normalizeWord)
      .filter((word) => word.length === WORD_LENGTH);
  } catch (error) {
    words = [];
  }

  const fallback = [
    "beach", "couch", "river", "crown", "ocean", "plant", "panel", "cloud", "stone", "light",
    "grain", "music", "piano", "story", "globe", "march", "smile", "train", "shark", "whale"
  ];

  const deduped = new Set(words.concat(fallback).filter(Boolean));
  return Array.from(deduped);
}

const WORD_POOL = loadWordList();
const WORD_SET = new Set(WORD_POOL);

class WordMatchGame extends BaseGame {
  static meta = {
    id: "word-match",
    name: "Word Match",
    description: "Everyone guesses the same hidden word. Score rewards quick solves and fewer tries."
  };

  constructor(options) {
    super(options);
    this.state = {
      roundIndex: 0,
      scores: {},
      attemptsByPlayer: {},
      roundResultsByPlayer: {},
      leaderboard: [],
      usedWords: [],
      currentRound: null
    };
  }

  start() {
    this.getPlayers().forEach((player) => this.ensurePlayer(player.id));
    this.startNextRound();
  }

  ensurePlayer(playerId) {
    if (playerId && this.state.scores[playerId] === undefined) {
      this.state.scores[playerId] = 0;
    }
    if (playerId && !this.state.attemptsByPlayer[playerId]) {
      this.state.attemptsByPlayer[playerId] = [];
    }
  }

  getConnectedPlayers() {
    return this.getPlayers().filter((player) => player.isConnected !== false);
  }

  pickTargetWord() {
    const unused = WORD_POOL.filter((word) => !this.state.usedWords.includes(word));
    const source = unused.length > 0 ? unused : WORD_POOL;
    const next = source[Math.floor(Math.random() * source.length)] || "couch";
    this.state.usedWords.push(next);
    return next;
  }

  startNextRound() {
    this.clearTimer("round-end");
    this.clearTimer("next-round");
    this.clearTimer("return-to-vote");

    const roundNumber = this.state.roundIndex + 1;
    const targetWord = this.pickTargetWord();
    const startedAt = Date.now();
    const endsAt = startedAt + ROUND_DURATION_MS;

    this.state.roundIndex = roundNumber;
    this.state.currentRound = {
      number: roundNumber,
      total: TOTAL_ROUNDS,
      targetWord,
      startedAt,
      endsAt,
      durationMs: ROUND_DURATION_MS,
      maxAttempts: MAX_ATTEMPTS,
      wordLength: WORD_LENGTH
    };
    this.state.roundResultsByPlayer = {};
    this.state.attemptsByPlayer = {};
    this.getPlayers().forEach((player) => this.ensurePlayer(player.id));

    this.setPhase("word_match_round");
    this.emitRoomState();

    this.schedule("round-end", ROUND_DURATION_MS, () => this.finishRound("timer"));
  }

  handleAction(playerId, action, payload, ack) {
    if (action !== "submit_guess") {
      this.acknowledge(ack, { ok: false, error: `Unsupported action: ${action}` });
      return;
    }

    if (this.room.phase !== "word_match_round") {
      this.acknowledge(ack, { ok: false, error: "This round is not accepting guesses right now." });
      return;
    }

    if (!this.hasPlayer(playerId)) {
      this.acknowledge(ack, { ok: false, error: "Player is not in this room." });
      return;
    }

    const round = this.state.currentRound;
    if (!round) {
      this.acknowledge(ack, { ok: false, error: "Round data is missing." });
      return;
    }

    this.ensurePlayer(playerId);

    if (this.state.roundResultsByPlayer[playerId]) {
      this.acknowledge(ack, { ok: false, error: "You already finished this word." });
      return;
    }

    const guess = normalizeWord(payload?.guess);
    if (guess.length !== WORD_LENGTH) {
      this.acknowledge(ack, { ok: false, error: `Enter a ${WORD_LENGTH}-letter word.` });
      return;
    }

    if (!WORD_SET.has(guess)) {
      this.acknowledge(ack, { ok: false, error: "Use a valid word from the dictionary." });
      return;
    }

    const attempts = this.state.attemptsByPlayer[playerId] || [];
    if (attempts.length >= MAX_ATTEMPTS) {
      this.acknowledge(ack, { ok: false, error: "No guesses remaining this round." });
      return;
    }

    const submittedAt = Date.now();
    const feedback = scoreGuess(guess, round.targetWord);
    const entry = {
      guess,
      feedback,
      submittedAt
    };
    attempts.push(entry);
    this.state.attemptsByPlayer[playerId] = attempts;

    let roundResult = null;
    if (guess === round.targetWord) {
      roundResult = this.buildSolvedResult(playerId, submittedAt);
      this.state.roundResultsByPlayer[playerId] = roundResult;
    } else if (attempts.length >= MAX_ATTEMPTS) {
      roundResult = this.buildFailedResult(playerId, "tries");
      this.state.roundResultsByPlayer[playerId] = roundResult;
    }

    this.emitRoomState();
    this.acknowledge(ack, {
      ok: true,
      solved: Boolean(roundResult?.solved),
      feedback,
      attemptsUsed: attempts.length,
      roundResult
    });

    if (this.allConnectedPlayersResolved()) {
      this.finishRound("all-done");
    }
  }

  buildSolvedResult(playerId, submittedAt) {
    const round = this.state.currentRound;
    const attempts = this.state.attemptsByPlayer[playerId] || [];
    const triesUsed = attempts.length;
    const elapsedMs = Math.max(0, submittedAt - round.startedAt);
    const remainingMs = Math.max(0, round.endsAt - submittedAt);
    const speedRatio = remainingMs / Math.max(1, round.durationMs);
    const attemptBonus = Math.max(0, (MAX_ATTEMPTS - triesUsed) * 18);
    const speedBonus = Math.round(speedRatio * 140);
    const pointsEarned = 120 + attemptBonus + speedBonus;
    this.state.scores[playerId] = (this.state.scores[playerId] || 0) + pointsEarned;

    return {
      solved: true,
      triesUsed,
      pointsEarned,
      totalScore: this.state.scores[playerId] || 0,
      elapsedMs,
      remainingMs,
      reason: "solved"
    };
  }

  buildFailedResult(playerId, reason = "timer") {
    const attempts = this.state.attemptsByPlayer[playerId] || [];
    return {
      solved: false,
      triesUsed: attempts.length,
      pointsEarned: 0,
      totalScore: this.state.scores[playerId] || 0,
      elapsedMs: this.state.currentRound ? Math.max(0, Date.now() - this.state.currentRound.startedAt) : 0,
      remainingMs: 0,
      reason
    };
  }

  allConnectedPlayersResolved() {
    const players = this.getConnectedPlayers();
    if (players.length === 0) return false;
    return players.every((player) => Boolean(this.state.roundResultsByPlayer[player.id]));
  }

  finishRound(reason = "timer") {
    if (this.room.phase !== "word_match_round") return;
    this.clearTimer("round-end");

    for (const player of this.getConnectedPlayers()) {
      if (!this.state.roundResultsByPlayer[player.id]) {
        this.state.roundResultsByPlayer[player.id] = this.buildFailedResult(player.id, reason);
      }
    }

    this.state.leaderboard = this.buildLeaderboard();
    const isFinalRound = this.state.roundIndex >= TOTAL_ROUNDS;
    this.setPhase(isFinalRound ? "word_match_results" : "word_match_round_results");
    this.emitRoomState();

    if (isFinalRound) {
      this.schedule("return-to-vote", FINAL_RESULTS_MS, () => {
        if (this.room.phase === "word_match_results") {
          this.manager.startGameVote(this.room.code);
        }
      });
      return;
    }

    this.schedule("next-round", RESULT_DURATION_MS, () => {
      if (this.room.phase === "word_match_round_results") {
        this.startNextRound();
      }
    });
  }

  onPlayerJoined(player) {
    this.ensurePlayer(player.id);
    this.emitRoomState();
  }

  onPlayerLeft() {
    if (this.room.phase === "word_match_round" && this.allConnectedPlayersResolved()) {
      this.finishRound("all-done");
    }
  }

  onPlayerIdChanged(previousId, nextId) {
    if (!previousId || !nextId || previousId === nextId) return;

    if (this.state.scores[previousId] !== undefined) {
      this.state.scores[nextId] = this.state.scores[previousId];
      delete this.state.scores[previousId];
    }

    if (this.state.attemptsByPlayer[previousId]) {
      this.state.attemptsByPlayer[nextId] = this.state.attemptsByPlayer[previousId];
      delete this.state.attemptsByPlayer[previousId];
    }

    if (this.state.roundResultsByPlayer[previousId]) {
      this.state.roundResultsByPlayer[nextId] = this.state.roundResultsByPlayer[previousId];
      delete this.state.roundResultsByPlayer[previousId];
    }
  }

  buildLeaderboard() {
    return this.getPlayers()
      .map((player) => ({
        id: player.id,
        name: player.name,
        character: player.character,
        score: this.state.scores[player.id] || 0,
        triesUsed: (this.state.roundResultsByPlayer[player.id]?.triesUsed) ?? (this.state.attemptsByPlayer[player.id]?.length || 0),
        solved: Boolean(this.state.roundResultsByPlayer[player.id]?.solved)
      }))
      .sort((left, right) => {
        if (right.score !== left.score) return right.score - left.score;
        if (left.solved !== right.solved) return left.solved ? -1 : 1;
        if (left.triesUsed !== right.triesUsed) return left.triesUsed - right.triesUsed;
        return left.name.localeCompare(right.name);
      });
  }

  buildBoardCards() {
    const leaderboard = this.buildLeaderboard();
    const maxScore = leaderboard.length > 0 ? Math.max(...leaderboard.map((entry) => entry.score), 1) : 1;

    return leaderboard.map((entry, index) => {
      const attempts = this.state.attemptsByPlayer[entry.id] || [];
      const result = this.state.roundResultsByPlayer[entry.id];
      let footer = "Waiting to start";
      let latestGuess = "";
      let latestFeedback = Array.from({ length: WORD_LENGTH }, () => "empty");

      if (attempts.length > 0) {
        const latestAttempt = attempts[attempts.length - 1];
        latestGuess = String(latestAttempt?.guess || "").toUpperCase();
        latestFeedback = Array.isArray(latestAttempt?.feedback)
          ? latestAttempt.feedback
          : Array.from({ length: WORD_LENGTH }, () => "empty");
      }

      if (this.room.phase === "word_match_round") {
        if (result?.solved) {
          footer = `Solved in ${result.triesUsed} ${result.triesUsed === 1 ? "try" : "tries"}`;
        } else if (attempts.length > 0) {
          footer = `${attempts.length}/${MAX_ATTEMPTS} tries · Last guess on TV`;
        } else {
          footer = "Ready to guess";
        }
      } else if (result?.solved) {
        footer = `Solved · +${result.pointsEarned} pts · ${result.triesUsed} tries`;
      } else {
        const revealedWord = String(this.state.currentRound?.targetWord || "").toUpperCase();
        footer = result?.reason === "tries"
          ? `Out of tries${revealedWord ? ` · Word was ${revealedWord}` : ""}`
          : "No solve before time ran out";
      }

      return {
        title: entry.name,
        footer,
        rank: index + 1,
        score: entry.score,
        character: entry.character,
        barRatio: entry.score / maxScore,
        latestGuess,
        latestFeedback: latestFeedback.join(",")
      };
    });
  }

  getPublicState() {
    return {
      leaderboard: this.buildLeaderboard(),
      currentRound: this.state.currentRound
    };
  }

  getTvView() {
    const round = this.state.currentRound;
    const isFinal = this.room.phase === "word_match_results";
    const isRoundResult = this.room.phase === "word_match_round_results";
    const layout = isFinal ? "word_guess_results" : "word_guess_board";
    const wordHeader = isFinal || isRoundResult
      ? round.targetWord.toUpperCase().split("").join(" ")
      : Array.from({ length: WORD_LENGTH }, () => "_").join(" ");

    let subtitle = `Round ${round.number} of ${round.total} · ${WORD_LENGTH}-letter word`;
    if (isFinal) {
      subtitle = "Final results";
    } else if (isRoundResult) {
      subtitle = `Round ${round.number} complete · Next word soon`;
    }

    return {
      layout,
      title: "Word Match",
      subtitle,
      description: isFinal || isRoundResult
        ? "Green means the letter is in the right spot. Yellow means the letter belongs in a different spot."
        : "Everyone gets the same hidden word. Faster solves and fewer guesses score higher.",
      maskedWord: wordHeader,
      roundEndsAt: this.room.phase === "word_match_round" ? round.endsAt : null,
      roundDurationMs: this.room.phase === "word_match_round" ? round.durationMs : 0,
      maxScore: Math.max(1, ...this.buildLeaderboard().map((entry) => entry.score || 0)),
      cards: this.buildBoardCards()
    };
  }

  getControllerView(playerId) {
    const round = this.state.currentRound;
    const attempts = this.state.attemptsByPlayer[playerId] || [];
    const result = this.state.roundResultsByPlayer[playerId] || null;
    const rows = [];

    for (let i = 0; i < MAX_ATTEMPTS; i += 1) {
      const entry = attempts[i];
      rows.push({
        guess: entry?.guess || "",
        feedback: entry?.feedback || Array.from({ length: WORD_LENGTH }, () => "empty")
      });
    }

    const isRoundActive = this.room.phase === "word_match_round";
    const canSubmit = isRoundActive && !result && attempts.length < MAX_ATTEMPTS;

    let detailMessage = `Round ${round.number} of ${round.total} · Guess the ${WORD_LENGTH}-letter word.`;
    if (result?.solved) {
      detailMessage = `Solved in ${result.triesUsed} ${result.triesUsed === 1 ? "try" : "tries"} for +${result.pointsEarned} points.`;
    } else if (result && !result.solved) {
      detailMessage = `Round over. The word was ${round.targetWord.toUpperCase()}.`;
    }

    return {
      layout: "word_guess",
      title: "Word Match",
      details: detailMessage,
      roundNumber: round.number,
      roundTotal: round.total,
      wordLength: WORD_LENGTH,
      maxAttempts: MAX_ATTEMPTS,
      attemptsUsed: attempts.length,
      playerScore: this.state.scores[playerId] || 0,
      roundEndsAt: isRoundActive ? round.endsAt : null,
      roundDurationMs: isRoundActive ? round.durationMs : 0,
      canSubmit,
      isRoundComplete: !isRoundActive,
      revealedWord: !isRoundActive ? round.targetWord.toUpperCase() : null,
      rows,
      latestResult: result
    };
  }

  getPrivateState(playerId) {
    const score = this.state.scores[playerId] || 0;
    return {
      gameId: this.id,
      title: "Your score",
      message: `${score} points total`,
      footer: "Use quick, accurate guesses to climb the TV leaderboard."
    };
  }
}

module.exports = WordMatchGame;
