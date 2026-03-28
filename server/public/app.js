// =======================
// CONFIG
// =======================
const API_BASE = "http://192.168.1.104:3000";
let socket = null;

// =======================
// HELPER FUNCTIONS
// =======================
function getQueryParam(name) {
  const params = new URLSearchParams(window.location.search);
  return params.get(name);
}

async function validateCode(code) {
  try {
    const res = await fetch(`${API_BASE}/api/room/${code}`);
    return res.ok;
  } catch {
    return false;
  }
}

function connectSocket(code, name) {
  socket = io(API_BASE);

  socket.on("connect", () => {
    console.log("Connected to server via Socket.IO");

    // Join the room
    socket.emit("join_room", { code, name });
  });

  socket.on("players_update", (players) => {
    console.log("Players updated:", players);
    const playerList = document.getElementById("playerList");
    if (playerList) {
      playerList.innerHTML = players.map(p => `<li>${p.name}</li>`).join("");
    }
  });

  socket.on("disconnect", () => {
    console.log("Disconnected from server");
  });
}

// =======================
// HOME PAGE
// =======================
async function joinGame() {
  const code = document.getElementById("codeInput").value.toUpperCase().trim();
  if (!code) return;

  const valid = await validateCode(code);
  if (!valid) {
    document.getElementById("error").innerText = "Invalid Code";
    return;
  }

  window.location.href = `/name?code=${code}`;
}

// =======================
// JOIN PAGE (QR FLOW)
// =======================
async function handleJoinPage() {
  const code = getQueryParam("code")?.toUpperCase()?.trim();

  if (!code) {
    window.location.href = "/";
    return;
  }

  const valid = await validateCode(code);
  if (!valid) {
    window.location.href = "/?error=invalid";
    return;
  }

  const joinInput = document.getElementById("joinCode");
  if (joinInput) joinInput.value = code; // optional prefill

  // Auto redirect to name input page
  window.location.href = `/name?code=${code}`;
}

// =======================
// NAME PAGE
// =======================
function submitName() {
  const name = document.getElementById("nameInput").value.trim();
  const code = getQueryParam("code")?.toUpperCase()?.trim();

  if (!name || !code) return;

  // Store locally
  localStorage.setItem("playerName", name);
  localStorage.setItem("roomCode", code);

  // Connect Socket.IO
  connectSocket(code, name);

  // Go to game page
  window.location.href = "/game";
}

// =======================
// GAME PAGE
// =======================
function loadGamePage() {
  const name = localStorage.getItem("playerName");
  const code = localStorage.getItem("roomCode");

  document.getElementById("playerInfo").innerText = `Name: ${name} | Room: ${code}`;

  // Connect Socket.IO if not already connected
  if (!socket) connectSocket(code, name);
}

// =======================
// AUTO PAGE DETECTION
// =======================
window.onload = () => {
  const path = window.location.pathname;

  if (path === "/join") handleJoinPage();
  if (path === "/game") loadGamePage();

  // Show error from redirect
  const error = getQueryParam("error");
  if (error === "invalid") {
    const el = document.getElementById("error");
    if (el) el.innerText = "Invalid Code";
  }
};