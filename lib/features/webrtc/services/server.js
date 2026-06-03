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
    const TURN_KEY_ID = "4b15e7ea79e50342df3ceda5c7dd53f7";
    const API_TOKEN = "4c1b26f18e9b299c52a5733a6aac771bf37a1ab7fbf763abec8a7e2a8a0c4e8f";

    // 1. Target the dedicated standalone RTC domain visible in your image blueprint
    const targetUrl = `https://rtc.live.cloudflare.com/v1/turn/keys/${TURN_KEY_ID}/credentials/generate-ice-servers`;
    
    console.log(`[WebRTC Engine] Connecting to direct edge target: ${targetUrl}`);

    // 2. Generate the explicit Base64 Basic Authentication token Cloudflare requires here
    const basicAuthToken = Buffer.from(`${TURN_KEY_ID}:${API_TOKEN}`).toString('base64');

    const cfResponse = await axios.post(
      targetUrl,
      { ttl: 86400 }, 
      {
        headers: {
          // Force Basic auth structure to match the WebRTC edge requirements
          'Authorization': `Basic ${basicAuthToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    // 3. Extract the response array directly from the root property payload
    if (!cfResponse.data || !cfResponse.data.iceServers) {
      throw new Error("Cloudflare response parsing failed: Missing iceServers data array.");
    }

    const fetchedIceServers = cfResponse.data.iceServers;
    const dynamicRoomId = `room_${Math.random().toString(36).substring(2, 11)}`;
    const passengerId = req.body.userId || `user_${Math.random().toString(36).substring(2, 7)}`;
    const flattenedIceConfigString = JSON.stringify(fetchedIceServers);

    waitingQueue.push({
      roomId: dynamicRoomId,
      userId: passengerId,
      cloudflareIceServers: fetchedIceServers
    });

    console.log(`[Handshake Successful] Room linked: ${dynamicRoomId}`);

    return res.status(200).json({
      "status": "waiting",
      "roomId": dynamicRoomId,
      "userId": passengerId,
      "iceConfigString": flattenedIceConfigString 
    });

  } catch (error) {
    if (error.response) {
      console.error("[WebRTC Gateway Error Response Data]:", error.response.data);
      console.error("[WebRTC Gateway Error Status Code]:", error.response.status);
    } else {
      console.error("[WebRTC System Error Message]:", error.message);
    }

    // Fall back to a safe status return so the chatbot flow node can process it cleanly
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