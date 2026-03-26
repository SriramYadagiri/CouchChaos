const BaseGame = require("./BaseGame");
const QUESTION_BANK = require("./Questionbank");

const QUESTION_DURATION_MS = 6000;
// How long to show the correct answer before advancing
const REVEAL_DURATION_MS = 3000;

const DIFFICULTY_SETTINGS = {
  1: { label: "Easy",   minPoints: 150,  maxSpeedBonus: 350 },
  2: { label: "Medium", minPoints: 250,  maxSpeedBonus: 750 },
  3: { label: "Hard",   minPoints: 400,  maxSpeedBonus: 1100 }
};

function getDifficultySettings(difficulty) {
  return DIFFICULTY_SETTINGS[difficulty] || DIFFICULTY_SETTINGS[2];
}

const TRIVIA_OPTION_COLORS = {
  red:    { label: "Red",    cardColor: "0xC0392BFF", background: "#c0392b", color: "#ffffff" },
  blue:   { label: "Blue",   cardColor: "0x2980B9FF", background: "#2980b9", color: "#ffffff" },
  yellow: { label: "Yellow", cardColor: "0xD4AC0DFF", background: "#d4ac0d", color: "#111111" },
  green:  { label: "Green",  cardColor: "0x239B56FF", background: "#239b56", color: "#ffffff" }
};

function normalizeAnswer(value) {
  return String(value || "").trim().toLowerCase();
}

function buildTriviaOptions(question) {
  return ["red", "blue", "yellow", "green"].map((colorKey) => ({
    color: colorKey,
    label: TRIVIA_OPTION_COLORS[colorKey].label,
    cardColor: TRIVIA_OPTION_COLORS[colorKey].cardColor,
    background: TRIVIA_OPTION_COLORS[colorKey].background,
    colorHex: TRIVIA_OPTION_COLORS[colorKey].color,
    text: question.options[colorKey]
  }));
}

class TriviaTossGame extends BaseGame {
  constructor(context) {
    super(context);
    this.state = {
      questionIndex: 0,
      currentQuestion: null,
      playerAnswers: {},
      scores: {},
      leaderboard: [],
      lastQuestionResults: {},
      // New: track the reveal phase
      revealCorrectColor: null,
      revealPhase: false
    };
  }

  start() {
    this.state.questionIndex = 0;
    this.state.currentQuestion = null;
    this.state.playerAnswers = {};
    this.state.leaderboard = [];
    this.state.scores = {};
    this.state.lastQuestionResults = {};
    this.state.revealCorrectColor = null;
    this.state.revealPhase = false;

    for (const player of this.getPlayers()) {
      this.state.scores[player.id] = 0;
    }

    this.advanceQuestion();
  }

  onPlayerIdChanged(previousId, nextId) {
    if (this.state.scores[previousId] !== undefined) {
      this.state.scores[nextId] = this.state.scores[previousId];
      delete this.state.scores[previousId];
    }

    if (this.state.playerAnswers[previousId]) {
      this.state.playerAnswers[nextId] = this.state.playerAnswers[previousId];
      delete this.state.playerAnswers[previousId];
    }

    if (this.state.lastQuestionResults[previousId]) {
      this.state.lastQuestionResults[nextId] = this.state.lastQuestionResults[previousId];
      delete this.state.lastQuestionResults[previousId];
    }
  }

  onPlayerJoined(player) {
    if (this.state.scores[player.id] === undefined) {
      this.state.scores[player.id] = 0;
    }
  }

  onPlayerLeft(playerId) {
    delete this.state.playerAnswers[playerId];
    delete this.state.scores[playerId];
    delete this.state.lastQuestionResults[playerId];
    if (!this.state.revealPhase) {
      this.maybeAdvanceQuestion();
    }
  }

  handleAction(playerId, action, payload, ack) {
    if (action !== "submit_answer") {
      this.acknowledge(ack, { ok: false, error: "Unknown trivia action" });
      return;
    }

    if (this.room.phase !== "trivia_question" || !this.state.currentQuestion) {
      this.acknowledge(ack, { ok: false, error: "Trivia question is not active" });
      return;
    }

    if (!this.hasPlayer(playerId)) {
      this.acknowledge(ack, { ok: false, error: "Player is not in this room" });
      return;
    }

    if (this.state.playerAnswers[playerId]) {
      this.acknowledge(ack, { ok: false, error: "Answer already submitted" });
      return;
    }

    if (!TRIVIA_OPTION_COLORS[payload?.answerColor]) {
      this.acknowledge(ack, { ok: false, error: "Invalid answer option" });
      return;
    }

    this.state.playerAnswers[playerId] = {
      answerColor: payload.answerColor,
      submittedAt: Date.now()
    };

    this.maybeAdvanceQuestion();
    this.acknowledge(ack, { ok: true });
  }

  maybeAdvanceQuestion() {
    if (this.room.phase !== "trivia_question" || !this.state.currentQuestion) return;
    if (this.state.revealPhase) return;

    const activePlayerIds = this.getPlayers().map((player) => player.id);
    if (activePlayerIds.length === 0) return;

    const allAnswered = activePlayerIds.every((playerId) => this.state.playerAnswers[playerId]);
    if (!allAnswered) {
      this.emitRoomState();
      return;
    }

    this.resolveCurrentQuestion();
  }

  resolveCurrentQuestion() {
    if (!this.state.currentQuestion) return;

    this.clearTimer("question-deadline");

    const question = QUESTION_BANK[this.state.currentQuestion.number - 1];
    const correctAnswer = normalizeAnswer(question.correctColor);
    const activePlayerIds = this.getPlayers().map((player) => player.id);
    const questionStartTime = this.state.currentQuestion.startedAt || Date.now();
    const questionDeadline = this.state.currentQuestion.endsAt || (questionStartTime + QUESTION_DURATION_MS);
    const leaderboard = this.buildLeaderboard();
    const placeByPlayerId = {};

    leaderboard.forEach((entry, index) => {
      placeByPlayerId[entry.id] = index + 1;
    });

    for (const playerId of activePlayerIds) {
      const answer = this.state.playerAnswers[playerId];
      const submittedAnswer = normalizeAnswer(answer?.answerColor);
      const isCorrect = submittedAnswer === correctAnswer;
      const pointsEarned = isCorrect
        ? this.calculatePoints(answer.submittedAt, questionStartTime, questionDeadline, question.difficulty)
        : 0;

      this.state.scores[playerId] = (this.state.scores[playerId] || 0) + pointsEarned;
    }

    const updatedLeaderboard = this.buildLeaderboard();
    const updatedPlaceByPlayerId = {};
    updatedLeaderboard.forEach((entry, index) => {
      updatedPlaceByPlayerId[entry.id] = index + 1;
    });

    for (const playerId of activePlayerIds) {
      const answer = this.state.playerAnswers[playerId];
      const submittedAnswer = normalizeAnswer(answer?.answerColor);
      const isCorrect = submittedAnswer === correctAnswer;
      const pointsEarned = isCorrect
        ? this.calculatePoints(answer.submittedAt, questionStartTime, questionDeadline, question.difficulty)
        : 0;
      const responseTimeMs = answer ? Math.max(0, answer.submittedAt - questionStartTime) : QUESTION_DURATION_MS;

      this.state.lastQuestionResults[playerId] = {
        questionNumber: this.state.currentQuestion.number,
        wasCorrect: isCorrect,
        pointsEarned,
        totalPoints: this.state.scores[playerId] || 0,
        place: updatedPlaceByPlayerId[playerId] || updatedLeaderboard.length,
        responseTimeMs,
        timedOut: !answer
      };
    }

    // Enter reveal phase — show correct answer for REVEAL_DURATION_MS
    this.state.revealCorrectColor = correctAnswer;
    this.state.revealPhase = true;
    this.emitRoomState();

    this.schedule("reveal-advance", REVEAL_DURATION_MS, () => {
      this.state.revealPhase = false;
      this.state.revealCorrectColor = null;
      this.advanceQuestion();
    });
  }

  calculatePoints(submittedAt, startedAt, endsAt, difficulty) {
    const { minPoints, maxSpeedBonus } = getDifficultySettings(difficulty);
    const timeRemainingMs = Math.max(0, endsAt - submittedAt);
    const questionDurationMs = Math.max(1, endsAt - startedAt);
    const speedBonus = Math.round((timeRemainingMs / questionDurationMs) * maxSpeedBonus);
    return minPoints + speedBonus;
  }

  advanceQuestion() {
    this.clearTimer("question-deadline");

    if (this.state.questionIndex >= QUESTION_BANK.length) {
      this.setPhase("trivia_leaderboard");
      this.state.currentQuestion = null;
      this.state.playerAnswers = {};
      this.state.leaderboard = this.buildLeaderboard();
      this.emitRoomState();

      this.schedule("return-to-vote", 8000, () => {
        if (this.room.phase === "trivia_leaderboard") {
          this.manager.startGameVote(this.room.code);
        }
      });
      return;
    }

    const question = QUESTION_BANK[this.state.questionIndex];
    const startedAt = Date.now();
    const endsAt = startedAt + QUESTION_DURATION_MS;
    const { label: difficultyLabel } = getDifficultySettings(question.difficulty);
    this.setPhase("trivia_question");
    this.state.currentQuestion = {
      prompt: question.prompt,
      number: this.state.questionIndex + 1,
      total: QUESTION_BANK.length,
      difficulty: question.difficulty,
      difficultyLabel,
      correctColor: question.correctColor,
      options: buildTriviaOptions(question),
      startedAt,
      endsAt,
      durationMs: QUESTION_DURATION_MS
    };
    this.state.playerAnswers = {};
    this.state.questionIndex += 1;
    this.schedule("question-deadline", QUESTION_DURATION_MS, () => {
      if (this.room.phase === "trivia_question" && !this.state.revealPhase) {
        this.resolveCurrentQuestion();
      }
    });
    this.emitRoomState();
  }

  buildLeaderboard() {
    return this.getPlayers()
      .map((player) => ({
        id: player.id,
        name: player.name,
        character: player.character,
        score: this.state.scores[player.id] || 0
      }))
      .sort((left, right) => {
        if (right.score !== left.score) return right.score - left.score;
        return left.name.localeCompare(right.name);
      });
  }

  // Count how many players have answered the current question
  getAnswerCount() {
    return Object.keys(this.state.playerAnswers).length;
  }

  // Count answers per color for the reveal phase
  getAnswerCountByColor() {
    const counts = { red: 0, blue: 0, yellow: 0, green: 0 };
    for (const answer of Object.values(this.state.playerAnswers)) {
      if (counts[answer.answerColor] !== undefined) {
        counts[answer.answerColor] += 1;
      }
    }
    return counts;
  }

  getPublicState() {
    return {
      currentQuestion: this.state.currentQuestion,
      leaderboard: this.state.leaderboard,
      // Expose answer count + reveal state publicly (TV needs it)
      answerCount: this.getAnswerCount(),
      totalPlayers: this.getPlayers().length,
      revealPhase: this.state.revealPhase,
      revealCorrectColor: this.state.revealCorrectColor,
      answerCountByColor: this.state.revealPhase ? this.getAnswerCountByColor() : null
    };
  }

  getTvView() {
    const answerCount = this.getAnswerCount();
    const totalPlayers = this.getPlayers().length;

    if (this.room.phase === "trivia_question") {
      const isReveal = this.state.revealPhase;
      const correctColor = this.state.currentQuestion.correctColor;
      const answerCountByColor = isReveal ? this.getAnswerCountByColor() : null;

      return {
        layout: isReveal ? "trivia_reveal" : "trivia_question",
        title: "Trivia Toss",
        subtitle: `Question ${this.state.currentQuestion.number} of ${this.state.currentQuestion.total} · ${this.state.currentQuestion.difficultyLabel}`,
        description: this.state.currentQuestion.prompt,
        questionEndsAt: this.state.currentQuestion.endsAt,
        questionDurationMs: this.state.currentQuestion.durationMs,
        answerCount,
        totalPlayers,
        correctColor: isReveal ? correctColor : null,
        answerCountByColor,
        cards: this.state.currentQuestion.options.map((option) => ({
          title: option.label,
          description: option.text,
          footer: isReveal
            ? (answerCountByColor ? `${answerCountByColor[option.color]} answered` : "")
            : (answerCount > 0 ? `${answerCount}/${totalPlayers} answered` : ""),
          cardColor: option.cardColor,
          isCorrect: isReveal ? option.color === correctColor : null
        }))
      };
    }

    if (this.room.phase === "trivia_leaderboard") {
      const lb = this.state.leaderboard;
      const maxScore = lb.length > 0 ? Math.max(...lb.map((e) => e.score), 1) : 1;
      return {
        layout: "trivia_leaderboard",
        title: "Trivia Toss Results",
        subtitle: "Leaderboard",
        description: "Returning to minigame voting shortly.",
        maxScore,
        cards: lb.map((entry, index) => ({
          title: entry.name,
          description: "",
          footer: `${entry.score} pts`,
          rank: index + 1,
          score: entry.score,
          character: entry.character,
          barRatio: entry.score / maxScore
        }))
      };
    }

    return null;
  }

  getControllerView(playerId) {
    const latestResult = playerId ? this.state.lastQuestionResults[playerId] : null;
    const myAnswer = playerId && this.state.playerAnswers[playerId]
      ? this.state.playerAnswers[playerId].answerColor
      : null;

    if (this.room.phase === "trivia_question") {
      const isReveal = this.state.revealPhase;
      const correctColor = isReveal ? this.state.currentQuestion.correctColor : null;
      const hasAnswered = Boolean(myAnswer);

      return {
        layout: "answer_grid",
        title: `Question ${this.state.currentQuestion.number} of ${this.state.currentQuestion.total}`,
        questionNumber: this.state.currentQuestion.number,
        difficultyLabel: this.state.currentQuestion.difficultyLabel,
        difficulty: this.state.currentQuestion.difficulty,
        details: this.state.currentQuestion.prompt,
        questionEndsAt: this.state.currentQuestion.endsAt,
        questionDurationMs: this.state.currentQuestion.durationMs,
        playerScore: playerId ? (this.state.scores[playerId] || 0) : 0,
        latestResult,
        hasAnswered,
        myAnswerColor: myAnswer,
        // Reveal fields
        isReveal,
        correctColor,
        options: this.state.currentQuestion.options.map((option) => ({
          id: option.color,
          label: option.label,
          description: option.text,
          background: option.background,
          color: option.colorHex,
          action: "submit_answer",
          payload: { answerColor: option.color },
          isMyAnswer: myAnswer === option.color,
          isCorrect: isReveal ? option.color === correctColor : null
        }))
      };
    }

    if (this.room.phase === "trivia_leaderboard") {
      const lb = this.buildLeaderboard();
      const maxScore = lb.length > 0 ? Math.max(...lb.map((e) => e.score), 1) : 1;
      return {
        layout: "leaderboard",
        title: "Final leaderboard",
        details: "Returning to minigame voting shortly.",
        latestResult,
        maxScore,
        items: lb.map((entry, index) => ({
          id: entry.id,
          label: entry.name,
          character: entry.character,
          value: `${entry.score} pts`,
          score: entry.score,
          rank: index + 1,
          barRatio: entry.score / maxScore
        }))
      };
    }

    return null;
  }
}

TriviaTossGame.meta = {
  id: "trivia-toss",
  name: "Trivia Toss",
  description: "A party quiz placeholder."
};

module.exports = TriviaTossGame;