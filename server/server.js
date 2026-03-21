const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const path = require("path");
const GameManager = require("./src/GameManager");
const gameRegistry = require("./src/games");

const app = express();
const server = http.createServer(app);
const io = new Server(server);
const gameManager = new GameManager({ io, gameRegistry });

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

function generateCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  let code;

  do {
    code = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
  } while (gameManager.getRoom(code));

  return code;
}

app.post("/api/create-room", (req, res) => {
  const code = generateCode();
  gameManager.createRoom(code);
  res.json({ code });
});

app.get("/api/room/:code", (req, res) => {
  const code = req.params.code.toUpperCase();
  const room = gameManager.getRoom(code);

  if (!room) {
    return res.status(404).json({ error: "Room not found" });
  }

  return res.json(gameManager.buildPublicRoomState(room));
});

app.post("/api/room/:code/start-game-vote", (req, res) => {
  const code = req.params.code.toUpperCase();
  const roomState = gameManager.startGameVote(code);

  if (!roomState) {
    return res.status(404).json({ error: "Room not found" });
  }

  return res.json(roomState);
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.get("/join", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.get("/name", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "name.html"));
});

app.get("/game", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "game.html"));
});

io.on("connection", (socket) => {
  console.log("Client connected:", socket.id);

  socket.on("join_room", ({ code, name, clientId }) => {
    const roomCode = String(code || "").toUpperCase();
    const result = gameManager.joinRoom(roomCode, socket, name, clientId);

    if (!result.ok) {
      socket.emit("error_message", result.error);
      return;
    }

    socket.emit("player_identity", {
      clientId: result.player.clientId,
      name: result.player.name
    });
  });

  socket.on("vote_game", ({ code, gameId }, ack) => {
    const roomCode = String(code || "").toUpperCase();
    const result = gameManager.voteForGame(roomCode, socket.id, gameId);

    if (typeof ack === "function") {
      ack(result);
    }

    if (!result.ok && result.error === "Invalid room") {
      socket.emit("error_message", result.error);
    }
  });

  socket.on("game_action", ({ code, action, payload }, ack) => {
    const roomCode = String(code || "").toUpperCase();
    gameManager.routeGameAction(roomCode, socket.id, action, payload, ack);
  });

  socket.on("disconnect", () => {
    gameManager.removeSocket(socket.id);
  });
});

const PORT = 3000;
server.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
