const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const axios = require('axios');

const app = express();
app.use(express.json()); // Essential for handling inbound JSON payloads from your chatbot

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Centralized session memory queue
const waitingQueue = [];

// 1. HEALTH CHECK: Prevents Render free-tier cold starts from dropping calls
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// 2. AGENT DASHBOARD API: Agents call this to pull the next user out of the queue
app.get('/api/next-user', (req, res) => {
  if (waitingQueue.length > 0) {
    const nextSession = waitingQueue.shift(); 
    
    return res.json({
      "roomId": nextSession.roomId,   // Maps to "room_xxxxxx"
      "userId": nextSession.userId,   // Maps to "user_xxxxxx"
      "status": "waiting"
    });
  }

  return res.json({ 
    "roomId": null, 
    "userId": null, 
    "status": "idle",
    "message": "No users waiting."
  });
});

// 3. CHATBOT INVOKE API ENDPOINT: Generates room details + Cloudflare tokens instantly
app.post('/api/handshake-escalation', async (req, res) => {
  try {
    // Standardizing credential keys using hardcoded fallback targets from your code script
    const ACCOUNT_ID = process.env.CLOUDFLARE_ACCOUNT_ID || "1776d2f73f94bb8713ff4f7ba3d6eb2e";
    const TURN_KEY_ID = process.env.CLOUDFLARE_TURN_KEY_ID || "4b15e7ea79e50342df3ceda5c7dd53f7";
    const API_TOKEN = process.env.CLOUDFLARE_API_TOKEN || "4c1b26f18e9b299c52a5733a6aac771bf37a1ab7fbf763abec8a7e2a8a0c4e8f";

    console.log(`[WebRTC Engine] Initializing API token handshake for TURN Key: ${TURN_KEY_ID}`);

    // Request parameters from Cloudflare using the exact production endpoint layout
    const cfResponse = await axios.post(
      `https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/calls/turn/keys/${TURN_KEY_ID}/credentials`,
      { ttl: 86400 }, // CRITICAL: Cloudflare requires a defined Time-To-Live payload body!
      {
        headers: {
          'Authorization': `Bearer ${API_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    // Verify Cloudflare data block exists safely
    if (!cfResponse.data || !cfResponse.data.result || !cfResponse.data.result.iceServers) {
      throw new Error("Cloudflare response parsing failed: Missing iceServers array data field.");
    }

    const fetchedIceServers = cfResponse.data.result.iceServers;

    // Generate unique structural tracking tokens for your cross-platform pipeline sessions
    const dynamicRoomId = `room_${Math.random().toString(36).substring(2, 11)}`;
    const passengerId = req.body.userId || `user_${Math.random().toString(36).substring(2, 7)}`;

    // Serialize the server properties into a safe string array container for your chatbot variable manager
    const flattenedIceConfigString = JSON.stringify(fetchedIceServers);

    // Push this session configuration into our waiting tracking array so the agent dashboard can find it
    waitingQueue.push({
      roomId: dynamicRoomId,
      userId: passengerId,
      cloudflareIceServers: fetchedIceServers
    });

    console.log(`[Queue Success] Room instantiated: ${dynamicRoomId} for user: ${passengerId}`);

    // Return flattened fields matching your chatbot workspace structure fields exactly
    return res.status(200).json({
      "status": "waiting",
      "roomId": dynamicRoomId,
      "userId": passengerId,
      "iceConfigString": flattenedIceConfigString 
    });

  } catch (error) {
    // Print out deep diagnostic error objects inside your Render logs console terminal
    if (error.response) {
      console.error("[WebRTC Gateway Error Response Data]:", error.response.data);
      console.error("[WebRTC Gateway Error Status Code]:", error.response.status);
    } else {
      console.error("[WebRTC System Error Message]:", error.message);
    }

    // Return a structured 200 payload flag back to the chatbot so the flow doesn't drop network connections
    return res.status(200).json({ 
      "status": "failed",
      "roomId": "",
      "userId": "",
      "iceConfigString": ""
    });
  }
});
// 4. UNIFIED SIGNALING ENGINE (Unified Socket.io Listeners)
io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  // Inbound Mobile Application Escalation Trigger
  socket.on('request-human', (data) => {
    const generatedRoomId = `room_${socket.id}`;
    socket.join(generatedRoomId);
    
    waitingQueue.push({
      roomId: generatedRoomId,
      userId: data.userId || `user_${socket.id}`
    });
    
    socket.emit('assigned-room', { room: generatedRoomId });
    console.log(`Added to queue via socket. Room: ${generatedRoomId}`);
  });

  // Client WebRTC Session Room Joining
  socket.on('join', (roomName) => {
    socket.join(roomName);
    console.log(`User ${socket.id} joined room: ${roomName}`);
  });

  // WebRTC Description Relaying (Offers)
  socket.on('offer', (data) => {
    console.log(`Relaying offer in room: ${data.room}`);
    socket.to(data.room).emit('offer', data);
  });

  // WebRTC Description Relaying (Answers)
  socket.on('answer', (data) => {
    console.log(`Relaying answer in room: ${data.room}`);
    socket.to(data.room).emit('answer', data);
  });

  // WebRTC ICE Candidate Network Path Interconnection
  socket.on('ice-candidate', (data) => {
    const targetRoom = data.room || data.roomId;
    if (targetRoom) {
      console.log(`Relaying ICE candidate from ${socket.id} into room: ${targetRoom}`);
      socket.to(targetRoom).emit('ice-candidate', data);
    }
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});