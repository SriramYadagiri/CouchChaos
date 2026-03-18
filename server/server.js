// =======================
// server.js
// =======================
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ===== In-memory store =====
const DEFAULT_GAMES = [
  {
    id: "couch-sprint",
    name: "Couch Sprint",
    description: "A fast reaction race placeholder."
  },
  {
    id: "trivia-toss",
    name: "Trivia Toss",
    description: "A party quiz placeholder."
  },
  {
    id: "tile-tumble",
    name: "Tile Tumble",
    description: "A puzzle battle placeholder."
  }
];

const TRIVIA_OPTION_COLORS = {
  red: { label: "Red", cardColor: "0xC0392BFF" },
  blue: { label: "Blue", cardColor: "0x2980B9FF" },
  yellow: { label: "Yellow", cardColor: "0xD4AC0DFF" },
  green: { label: "Green", cardColor: "0x239B56FF" }
};

const TRIVIA_TOSS_QUESTION_BANK = {
  q1: {
    prompt: "Placeholder Question 1",
    correctColor: "red",
    options: {
      red: "Placeholder Answer 1",
      blue: "Placeholder Wrong 1B",
      yellow: "Placeholder Wrong 1C",
      green: "Placeholder Wrong 1D"
    }
  },
  q2: {
    prompt: "Placeholder Question 2",
    correctColor: "blue",
    options: {
      red: "Placeholder Wrong 2A",
      blue: "Placeholder Answer 2",
      yellow: "Placeholder Wrong 2C",
      green: "Placeholder Wrong 2D"
    }
  },
  q3: {
    prompt: "Placeholder Question 3",
    correctColor: "yellow",
    options: {
      red: "Placeholder Wrong 3A",
      blue: "Placeholder Wrong 3B",
      yellow: "Placeholder Answer 3",
      green: "Placeholder Wrong 3D"
    }
  },
  q4: {
    prompt: "Placeholder Question 4",
    correctColor: "green",
    options: {
      red: "Placeholder Wrong 4A",
      blue: "Placeholder Wrong 4B",
      yellow: "Placeholder Wrong 4C",
      green: "Placeholder Answer 4"
    }
  },
  q5: {
    prompt: "Placeholder Question 5",
    correctColor: "red",
    options: {
      red: "Placeholder Answer 5",
      blue: "Placeholder Wrong 5B",
      yellow: "Placeholder Wrong 5C",
      green: "Placeholder Wrong 5D"
    }
  },
  q6: {
    prompt: "Placeholder Question 6",
    correctColor: "blue",
    options: {
      red: "Placeholder Wrong 6A",
      blue: "Placeholder Answer 6",
      yellow: "Placeholder Wrong 6C",
      green: "Placeholder Wrong 6D"
    }
  },
  q7: {
    prompt: "Placeholder Question 7",
    correctColor: "yellow",
    options: {
      red: "Placeholder Wrong 7A",
      blue: "Placeholder Wrong 7B",
      yellow: "Placeholder Answer 7",
      green: "Placeholder Wrong 7D"
    }
  },
  q8: {
    prompt: "Placeholder Question 8",
    correctColor: "green",
    options: {
      red: "Placeholder Wrong 8A",
      blue: "Placeholder Wrong 8B",
      yellow: "Placeholder Wrong 8C",
      green: "Placeholder Answer 8"
    }
  },
  q9: {
    prompt: "Placeholder Question 9",
    correctColor: "red",
    options: {
      red: "Placeholder Answer 9",
      blue: "Placeholder Wrong 9B",
      yellow: "Placeholder Wrong 9C",
      green: "Placeholder Wrong 9D"
    }
  },
  q10: {
    prompt: "Placeholder Question 10",
    correctColor: "blue",
    options: {
      red: "Placeholder Wrong 10A",
      blue: "Placeholder Answer 10",
      yellow: "Placeholder Wrong 10C",
      green: "Placeholder Wrong 10D"
    }
  }
};

const TRIVIA_TOSS_QUESTIONS = Object.values(TRIVIA_TOSS_QUESTION_BANK);

const rooms = {}; // { CODE: { players: [], phase: 'lobby' } }

// ===== Helpers =====
function generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let code;
  do {
    code = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  } while (rooms[code]);
  return code;
}

function cloneGames() {
  return DEFAULT_GAMES.map((game) => ({ ...game, votes: 0 }));
}

function normalizeAnswer(value) {
  return String(value || "").trim().toLowerCase();
}

function buildTriviaOptions(question) {
  return ["red", "blue", "yellow", "green"].map((colorKey) => ({
    color: colorKey,
    label: TRIVIA_OPTION_COLORS[colorKey].label,
    cardColor: TRIVIA_OPTION_COLORS[colorKey].cardColor,
    text: question.options[colorKey]
  }));
}

function buildLeaderboard(room) {
  return (room.players || [])
    .map((player) => ({
      id: player.id,
      name: player.name,
      score: room.scores?.[player.id] || 0
    }))
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return a.name.localeCompare(b.name);
    });
}

function buildPublicRoomState(room) {
  return {
    phase: room.phase,
    players: (room.players || []).map((player) => ({
      name: player.name
    })),
    games: room.games || [],
    selectedGame: room.selectedGame,
    currentQuestion: room.currentQuestion,
    leaderboard: room.leaderboard || []
  };
}

function emitRoomState(code) {
  if (!rooms[code]) return;
  io.to(code).emit("game_state", buildPublicRoomState(rooms[code]));
}

function tallyVotes(room) {
  const voteCounts = {};

  for (const game of room.games || []) {
    voteCounts[game.id] = 0;
  }

  for (const gameId of Object.values(room.gameVotes || {})) {
    if (voteCounts[gameId] !== undefined) {
      voteCounts[gameId] = voteCounts[gameId] + 1;
    }
  }

  room.games = (room.games || []).map((game) => ({
    ...game,
    votes: voteCounts[game.id] || 0
  }));
}

function finalizeGameVote(code) {
  const room = rooms[code];
  if (!room || !room.games || room.games.length === 0) return;

  tallyVotes(room);

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

  const selectedGame = tiedGames[Math.floor(Math.random() * tiedGames.length)];
  room.phase = "game_selected";
  room.selectedGame = selectedGame;

  emitRoomState(code);

  if (selectedGame.id === "trivia-toss") {
    startTriviaToss(code);
  }
}

function maybeFinalizeGameVote(code) {
  const room = rooms[code];
  if (!room || room.phase !== "game_select") return;
  if ((room.players || []).length === 0) return;

  const voteCount = Object.keys(room.gameVotes || {}).length;
  if (voteCount >= room.players.length) {
    finalizeGameVote(code);
  } else {
    tallyVotes(room);
    emitRoomState(code);
  }
}

function startGameVote(code) {
  const room = rooms[code];
  if (!room) return;

  room.phase = 'game_select';
  room.games = cloneGames();
  room.gameVotes = {};
  room.selectedGame = null;
  room.currentQuestion = null;
  room.questionIndex = 0;
  room.playerAnswers = {};
  room.scores = room.scores || {};
  room.leaderboard = [];
  room.returnToVoteAt = null;

  for (const player of room.players || []) {
    if (room.scores[player.id] === undefined) {
      room.scores[player.id] = 0;
    }
  }

  emitRoomState(code);
}

function startTriviaToss(code) {
  const room = rooms[code];
  if (!room) return;

  room.scores = {};
  for (const player of room.players || []) {
    room.scores[player.id] = 0;
  }

  room.questionIndex = 0;
  room.playerAnswers = {};
  room.leaderboard = [];
  room.returnToVoteAt = null;

  advanceTriviaQuestion(code);
}

function advanceTriviaQuestion(code) {
  const room = rooms[code];
  if (!room) return;

  if (room.questionIndex >= TRIVIA_TOSS_QUESTIONS.length) {
    room.phase = "trivia_leaderboard";
    room.currentQuestion = null;
    room.playerAnswers = {};
    room.leaderboard = buildLeaderboard(room);
    room.returnToVoteAt = Date.now() + 8000;
    emitRoomState(code);

    setTimeout(() => {
      const latestRoom = rooms[code];
      if (!latestRoom) return;
      if (latestRoom.phase === "trivia_leaderboard" && latestRoom.returnToVoteAt && Date.now() >= latestRoom.returnToVoteAt) {
        startGameVote(code);
      }
    }, 8000);
    return;
  }

  const question = TRIVIA_TOSS_QUESTIONS[room.questionIndex];
  room.phase = "trivia_question";
  room.currentQuestion = {
    prompt: question.prompt,
    number: room.questionIndex + 1,
    total: TRIVIA_TOSS_QUESTIONS.length,
    options: buildTriviaOptions(question)
  };
  room.playerAnswers = {};
  room.questionIndex += 1;

  emitRoomState(code);
}

function maybeAdvanceTrivia(code) {
  const room = rooms[code];
  if (!room || room.phase !== "trivia_question" || !room.currentQuestion) return;

  const activePlayerIds = (room.players || []).map((player) => player.id);
  if (activePlayerIds.length === 0) return;

  const allAnswered = activePlayerIds.every((playerId) => room.playerAnswers?.[playerId]);
  if (!allAnswered) {
    emitRoomState(code);
    return;
  }

  const question = TRIVIA_TOSS_QUESTIONS[room.currentQuestion.number - 1];
  const correctAnswer = normalizeAnswer(question.correctColor);

  for (const playerId of activePlayerIds) {
    const submittedAnswer = normalizeAnswer(room.playerAnswers[playerId]?.answerColor);
    if (submittedAnswer === correctAnswer) {
      room.scores[playerId] = (room.scores[playerId] || 0) + 1;
    }
  }

  advanceTriviaQuestion(code);
}

// ===== Routes =====
app.post('/api/create-room', (req, res) => {
  const code = generateCode();
  rooms[code] = {
    players: [],
    phase: 'lobby',
    games: [],
    gameVotes: {},
    selectedGame: null,
    currentQuestion: null,
    questionIndex: 0,
    playerAnswers: {},
    scores: {},
    leaderboard: [],
    returnToVoteAt: null
  };
  res.json({ code });
});

app.get('/api/room/:code', (req, res) => {
  const code = req.params.code.toUpperCase();
  if (!rooms[code]) return res.status(404).json({ error: 'Room not found' });
  res.json(buildPublicRoomState(rooms[code]));
});

app.post('/api/room/:code/start-game-vote', (req, res) => {
  const code = req.params.code.toUpperCase();
  const room = rooms[code];

  if (!room) return res.status(404).json({ error: 'Room not found' });

  startGameVote(code);

  res.json(buildPublicRoomState(room));
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/join', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/name', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'name.html'));
});

app.get('/game', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'game.html'));
});

// ===== Socket.IO =====
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('join_room', ({ code, name }) => {
    code = code.toUpperCase();

    if (!rooms[code]) {
      socket.emit('error_message', 'Invalid room');
      return;
    }

    const existingPlayer = rooms[code].players.find((player) => player.name === name);
    if (existingPlayer) {
      const previousId = existingPlayer.id;
      socket.join(code);
      if (rooms[code].scores?.[previousId] !== undefined) {
        rooms[code].scores[socket.id] = rooms[code].scores[previousId];
        delete rooms[code].scores[previousId];
      }
      if (rooms[code].gameVotes?.[previousId]) {
        rooms[code].gameVotes[socket.id] = rooms[code].gameVotes[previousId];
        delete rooms[code].gameVotes[previousId];
      }
      if (rooms[code].playerAnswers?.[previousId]) {
        rooms[code].playerAnswers[socket.id] = rooms[code].playerAnswers[previousId];
        delete rooms[code].playerAnswers[previousId];
      }
      existingPlayer.id = socket.id;
      io.to(code).emit('players_update', rooms[code].players);
      emitRoomState(code);
      return;
    }

    const player = { id: socket.id, name };
    rooms[code].players.push(player);
    rooms[code].scores[socket.id] = rooms[code].scores[socket.id] || 0;

    socket.join(code);

    io.to(code).emit('players_update', rooms[code].players);
    emitRoomState(code);
  });

  socket.on('vote_game', ({ code, gameId }, ack) => {
    code = code.toUpperCase();
    const room = rooms[code];
    const respond = typeof ack === "function" ? ack : () => {};

    if (!room) {
      socket.emit('error_message', 'Invalid room');
      respond({ ok: false, error: 'Invalid room' });
      return;
    }

    if (room.phase !== 'game_select') {
      respond({ ok: false, error: 'Voting is not active' });
      return;
    }

    const isPlayerInRoom = room.players.some((player) => player.id === socket.id);
    if (!isPlayerInRoom) {
      respond({ ok: false, error: 'Player is not in this room' });
      return;
    }

    const selectedGame = (room.games || []).find((game) => game.id === gameId);
    if (!selectedGame) {
      respond({ ok: false, error: 'Invalid game' });
      return;
    }

    if (room.gameVotes[socket.id]) {
      respond({ ok: false, error: 'Vote already submitted' });
      return;
    }

    room.gameVotes[socket.id] = gameId;
    maybeFinalizeGameVote(code);
    respond({ ok: true, gameId });
  });

  socket.on('submit_answer', ({ code, answerColor }, ack) => {
    code = code.toUpperCase();
    const room = rooms[code];
    const respond = typeof ack === "function" ? ack : () => {};

    if (!room) {
      respond({ ok: false, error: 'Invalid room' });
      return;
    }

    if (room.phase !== 'trivia_question' || !room.currentQuestion) {
      respond({ ok: false, error: 'Trivia question is not active' });
      return;
    }

    const isPlayerInRoom = room.players.some((player) => player.id === socket.id);
    if (!isPlayerInRoom) {
      respond({ ok: false, error: 'Player is not in this room' });
      return;
    }

    if (room.playerAnswers[socket.id]) {
      respond({ ok: false, error: 'Answer already submitted' });
      return;
    }

    if (!TRIVIA_OPTION_COLORS[answerColor]) {
      respond({ ok: false, error: 'Invalid answer option' });
      return;
    }

    room.playerAnswers[socket.id] = {
      answerColor,
      submittedAt: Date.now()
    };

    maybeAdvanceTrivia(code);
    respond({ ok: true });
  });

  socket.on('disconnect', () => {
    for (const code in rooms) {
      rooms[code].players = rooms[code].players.filter(p => p.id !== socket.id);
      if (rooms[code].gameVotes) {
        delete rooms[code].gameVotes[socket.id];
      }
      if (rooms[code].playerAnswers) {
        delete rooms[code].playerAnswers[socket.id];
      }
      tallyVotes(rooms[code]);
      io.to(code).emit('players_update', rooms[code].players);
      maybeFinalizeGameVote(code);
      maybeAdvanceTrivia(code);
    }
  });
});

// ===== Start Server =====
const PORT = 3000;
server.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
