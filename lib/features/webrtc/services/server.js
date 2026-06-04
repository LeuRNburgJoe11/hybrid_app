const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const axios = require('axios');

const app = express();
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// ─── Environment Variables ────────────────────────────────────────────────────
// Set these in your Render.com dashboard under Environment Variables.
// NEVER hardcode secrets in source code.
const TURN_KEY_ID = process.env.CF_TURN_KEY_ID;
const CF_API_TOKEN = process.env.CF_API_TOKEN;

if (!TURN_KEY_ID || !CF_API_TOKEN) {
  console.error("[FATAL] CF_TURN_KEY_ID or CF_API_TOKEN environment variables are not set.");
}

// ─── Centralized session memory queue ────────────────────────────────────────
const waitingQueue = [];

// ─── 1. HEALTH CHECK ─────────────────────────────────────────────────────────
// Prevents Render free-tier cold starts from dropping calls
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// ─── 2. AGENT DASHBOARD API ──────────────────────────────────────────────────
// Agents call this to pull the next user out of the queue
app.get('/api/next-user', (req, res) => {
  if (waitingQueue.length > 0) {
    const nextSession = waitingQueue.shift();
    return res.json({
      roomId: nextSession.roomId,
      userId: nextSession.userId,
      status: "waiting"
    });
  }
  return res.json({
    roomId: null,
    userId: null,
    status: "idle",
    message: "No users waiting."
  });
});

// ─── 3. CHATBOT INVOKE API ENDPOINT ──────────────────────────────────────────
// Called by your chatbot's "Invoke AI" block to generate Cloudflare TURN
// credentials and a room. Returns a flat response the chatbot can read directly.
app.post('/api/handshake-escalation', async (req, res) => {
  try {
    // FIX 1: Correct Cloudflare endpoint — "generate", not "generate-ice-servers"
    const targetUrl = `https://rtc.live.cloudflare.com/v1/turn/keys/${TURN_KEY_ID}/credentials/generate`;

    console.log(`[WebRTC Engine] Requesting TURN credentials from: ${targetUrl}`);

    // FIX 2: Bearer token auth using the API token — NOT Basic auth with the key ID
    const cfResponse = await axios.post(
      targetUrl,
      { ttl: 86400 },
      {
        headers: {
          'Authorization': `Bearer ${CF_API_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (!cfResponse.data || !cfResponse.data.iceServers) {
      throw new Error("Cloudflare response missing iceServers.");
    }

    // Cloudflare sometimes returns iceServers as a plain object instead of an array.
    // Normalise to array so .find() always works.
    const raw = cfResponse.data.iceServers;
    const iceServers = Array.isArray(raw) ? raw : [raw];

    console.log("[Cloudflare Response] iceServers:", JSON.stringify(iceServers));

    const turnServer = iceServers.find(s => s.username && s.credential);

    if (!turnServer) {
      throw new Error("No TURN server with credentials found in Cloudflare response.");
    }

    const dynamicRoomId = `room_${Math.random().toString(36).substring(2, 11)}`;
    const passengerId = req.body.userId || `user_${Math.random().toString(36).substring(2, 7)}`;

    // FIX 4: Push to queue only once, here in the REST handler.
    // The socket 'request-human' event is for socket-only flows — don't mix them.
    waitingQueue.push({
      roomId: dynamicRoomId,
      userId: passengerId,
      iceServers: iceServers
    });

    console.log(`[Handshake OK] Room: ${dynamicRoomId} | User: ${passengerId}`);

    // FIX 5: Return structured fields Flutter can access directly — no JSON string.
    // turnUrls / turnUsername / turnCredential are flat fields your chatbot
    // "Invoke AI" response body can map to variables cleanly.
    return res.status(200).json({
      status: "waiting",
      roomId: dynamicRoomId,
      userId: passengerId,
      // Flat TURN fields for chatbot variable mapping
      turnUrls: turnServer.urls,           // e.g. ["turn:turn.cloudflare.com:3478?transport=udp", ...]
      turnUsername: turnServer.username,    // ephemeral username
      turnCredential: turnServer.credential // ephemeral credential
    });

  } catch (error) {
    if (error.response) {
      console.error("[Cloudflare Error]:", error.response.status, error.response.data);
    } else {
      console.error("[Server Error]:", error.message);
    }

    return res.status(200).json({
      status: "failed",
      roomId: "",
      userId: "",
      turnUrls: [],
      turnUsername: "",
      turnCredential: ""
    });
  }
});

// ─── 4. SIGNALING ENGINE ──────────────────────────────────────────────────────
io.on('connection', (socket) => {
  console.log(`[Socket] Connected: ${socket.id}`);

  // Mobile app socket-based escalation (used when NOT going through chatbot REST flow)
  socket.on('request-human', (data) => {
    const generatedRoomId = `room_${socket.id}`;
    socket.join(generatedRoomId);

    // Only push to queue if this room isn't already queued via REST
    const alreadyQueued = waitingQueue.some(s => s.roomId === generatedRoomId);
    if (!alreadyQueued) {
      waitingQueue.push({
        roomId: generatedRoomId,
        userId: data.userId || `user_${socket.id}`
      });
    }

    socket.emit('assigned-room', { room: generatedRoomId });
    console.log(`[Queue] Added via socket. Room: ${generatedRoomId}`);
  });

  // Join a signaling room
  socket.on('join', (roomId) => {
    socket.join(roomId);
    console.log(`[Socket] ${socket.id} joined room: ${roomId}`);

    // Notify other peers in the room that someone joined so they can create an offer
    socket.to(roomId).emit('peer-joined', { socketId: socket.id });
  });

  // Relay WebRTC offer
  socket.on('offer', (data) => {
    console.log(`[Relay] Offer → room: ${data.roomId}`);
    socket.to(data.roomId).emit('offer', data);
  });

  // Relay WebRTC answer
  socket.on('answer', (data) => {
    console.log(`[Relay] Answer → room: ${data.roomId}`);
    socket.to(data.roomId).emit('answer', data);
  });

  // Relay ICE candidates
  // Uses roomId consistently (matching Flutter's emit key)
  socket.on('ice-candidate', (data) => {
    const targetRoom = data.roomId;
    if (targetRoom) {
      console.log(`[Relay] ICE candidate from ${socket.id} → room: ${targetRoom}`);
      socket.to(targetRoom).emit('ice-candidate', data);
    }
  });

  socket.on('leave-room', (data) => {
    console.log(`[Socket] ${socket.id} left. Reason: ${data?.reason}`);
  });

  socket.on('disconnect', () => {
    console.log(`[Socket] Disconnected: ${socket.id}`);
  });
});

// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});