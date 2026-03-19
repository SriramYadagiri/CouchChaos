const BaseGame = require("./BaseGame");

const TRIVIA_OPTION_COLORS = {
  red: { label: "Red", cardColor: "0xC0392BFF", background: "#c0392b", color: "#ffffff" },
  blue: { label: "Blue", cardColor: "0x2980B9FF", background: "#2980b9", color: "#ffffff" },
  yellow: { label: "Yellow", cardColor: "0xD4AC0DFF", background: "#d4ac0d", color: "#111111" },
  green: { label: "Green", cardColor: "0x239B56FF", background: "#239b56", color: "#ffffff" }
};

const QUESTION_BANK = [
  {
    prompt: "Placeholder Question 1",
    correctColor: "red",
    options: {
      red: "Placeholder Answer 1",
      blue: "Placeholder Wrong 1B",
      yellow: "Placeholder Wrong 1C",
      green: "Placeholder Wrong 1D"
    }
  },
  {
    prompt: "Placeholder Question 2",
    correctColor: "blue",
    options: {
      red: "Placeholder Wrong 2A",
      blue: "Placeholder Answer 2",
      yellow: "Placeholder Wrong 2C",
      green: "Placeholder Wrong 2D"
    }
  },
  {
    prompt: "Placeholder Question 3",
    correctColor: "yellow",
    options: {
      red: "Placeholder Wrong 3A",
      blue: "Placeholder Wrong 3B",
      yellow: "Placeholder Answer 3",
      green: "Placeholder Wrong 3D"
    }
  },
  {
    prompt: "Placeholder Question 4",
    correctColor: "green",
    options: {
      red: "Placeholder Wrong 4A",
      blue: "Placeholder Wrong 4B",
      yellow: "Placeholder Wrong 4C",
      green: "Placeholder Answer 4"
    }
  }
];

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
      leaderboard: []
    };
  }

  start() {
    this.state.questionIndex = 0;
    this.state.currentQuestion = null;
    this.state.playerAnswers = {};
    this.state.leaderboard = [];
    this.state.scores = {};

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
  }

  onPlayerJoined(player) {
    if (this.state.scores[player.id] === undefined) {
      this.state.scores[player.id] = 0;
    }
  }

  onPlayerLeft(playerId) {
    delete this.state.playerAnswers[playerId];
    delete this.state.scores[playerId];
    this.maybeAdvanceQuestion();
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

    const activePlayerIds = this.getPlayers().map((player) => player.id);
    if (activePlayerIds.length === 0) return;

    const allAnswered = activePlayerIds.every((playerId) => this.state.playerAnswers[playerId]);
    if (!allAnswered) {
      this.emitRoomState();
      return;
    }

    const question = QUESTION_BANK[this.state.currentQuestion.number - 1];
    const correctAnswer = normalizeAnswer(question.correctColor);

    for (const playerId of activePlayerIds) {
      const submittedAnswer = normalizeAnswer(this.state.playerAnswers[playerId]?.answerColor);
      if (submittedAnswer === correctAnswer) {
        this.state.scores[playerId] = (this.state.scores[playerId] || 0) + 1;
      }
    }

    this.advanceQuestion();
  }

  advanceQuestion() {
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
    this.setPhase("trivia_question");
    this.state.currentQuestion = {
      prompt: question.prompt,
      number: this.state.questionIndex + 1,
      total: QUESTION_BANK.length,
      options: buildTriviaOptions(question)
    };
    this.state.playerAnswers = {};
    this.state.questionIndex += 1;
    this.emitRoomState();
  }

  buildLeaderboard() {
    return this.getPlayers()
      .map((player) => ({
        id: player.id,
        name: player.name,
        score: this.state.scores[player.id] || 0
      }))
      .sort((left, right) => {
        if (right.score !== left.score) return right.score - left.score;
        return left.name.localeCompare(right.name);
      });
  }

  getPublicState() {
    return {
      currentQuestion: this.state.currentQuestion,
      leaderboard: this.state.leaderboard
    };
  }

  getTvView() {
    if (this.room.phase === "trivia_question") {
      return {
        layout: "trivia_question",
        title: "Trivia Toss",
        subtitle: `Question ${this.state.currentQuestion.number} of ${this.state.currentQuestion.total}`,
        description: this.state.currentQuestion.prompt,
        cards: this.state.currentQuestion.options.map((option) => ({
          title: option.label,
          description: option.text,
          footer: "",
          cardColor: option.cardColor
        }))
      };
    }

    if (this.room.phase === "trivia_leaderboard") {
      return {
        layout: "leaderboard",
        title: "Trivia Toss Results",
        subtitle: "Leaderboard",
        description: "Returning to minigame voting shortly.",
        cards: this.state.leaderboard.map((entry) => ({
          title: entry.name,
          description: "",
          footer: `${entry.score} pts`
        }))
      };
    }

    return null;
  }

  getControllerView() {
    if (this.room.phase === "trivia_question") {
      return {
        layout: "answer_grid",
        title: `Question ${this.state.currentQuestion.number} of ${this.state.currentQuestion.total}`,
        details: this.state.currentQuestion.prompt,
        options: this.state.currentQuestion.options.map((option) => ({
          id: option.color,
          label: option.label,
          description: option.text,
          background: option.background,
          color: option.colorHex,
          action: "submit_answer",
          payload: {
            answerColor: option.color
          }
        }))
      };
    }

    if (this.room.phase === "trivia_leaderboard") {
      return {
        layout: "leaderboard",
        title: "Final leaderboard",
        details: "Returning to minigame voting shortly.",
        items: this.state.leaderboard.map((entry) => ({
          id: entry.id,
          label: entry.name,
          value: `${entry.score} pts`
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
