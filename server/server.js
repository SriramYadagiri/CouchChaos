const express = require("express")
const http = require("http")
const { Server } = require("socket.io")
const cors = require("cors")

const app = express()
app.use(cors())
app.use(express.json())

const server = http.createServer(app)
const io = new Server(server, { cors: { origin: "*" } })

const rooms = {}

function generateRoomCode() {
  const letters = "ABCDEFGHJKMNPQRSTUVWXYZ"
  let code = ""
  for (let i = 0; i < 4; i++) {
    code += letters[Math.floor(Math.random() * letters.length)]
  }
  return code
}

function createRoom() {
  const code = generateRoomCode()

  rooms[code] = {
    code,
    players: [],
    phase: "lobby",
    prompt: "",
    answers: {},
    votes: {}
  }

  return rooms[code]
}

app.post("/create-room", (req, res) => {
  const room = createRoom()
  console.log(room)
  res.json(room)
})

app.get("/room/:code", (req, res) => {
  const room = rooms[req.params.code]
  if (!room) return res.status(404).json({ error: "Room not found" })
  res.json(room)
})

io.on("connection", socket => {

  socket.on("join_room", ({ code, name }) => {
    const room = rooms[code]
    if (!room) return

    const player = {
      id: socket.id,
      name,
      score: 0
    }

    room.players.push(player)
    socket.join(code)

    io.to(code).emit("players_update", room.players)
  })

  socket.on("submit_answer", ({ code, answer }) => {
    const room = rooms[code]
    if (!room) return

    room.answers[socket.id] = answer

    io.to(code).emit("answers_update", room.answers)
  })

  socket.on("submit_vote", ({ code, vote }) => {
    const room = rooms[code]
    if (!room) return

    if (!room.votes[vote]) room.votes[vote] = 0
    room.votes[vote]++

    io.to(code).emit("votes_update", room.votes)
  })

})

server.listen(3000, () => {
  console.log("Server running on port 3000")
})