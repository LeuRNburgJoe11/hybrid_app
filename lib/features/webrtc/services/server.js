const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Add this near the top of your server.js
const waitingQueue = [];

// Health check endpoint — prevents Render free-tier cold starts from
// stalling the WebRTC handshake. Flutter app pings this before joining.
app.get('/health', (req, res) => res.json({ status: 'ok' }));

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  // Flutter emits 'join' with a plain roomId string.
  socket.on('join', (roomName) => {
    socket.join(roomName);
    console.log(`User ${socket.id} joined room: ${roomName}`);
  });

  // Relay using data.room to match what Flutter emits.
  socket.on('offer', (data) => {
    console.log(`Relaying offer in room: ${data.room}`);
    socket.to(data.room).emit('offer', data);
  });

  socket.on('answer', (data) => {
    console.log(`Relaying answer in room: ${data.room}`);
    socket.to(data.room).emit('answer', data);
  });

  // ICE candidates routing setup
  socket.on('ice-candidate', (data) => {
    const targetRoom = data.room || data.roomId;
    if (targetRoom) {
      console.log(`Relaying ICE candidate from ${socket.id} into room: ${targetRoom}`);
      socket.to(targetRoom).emit('ice-candidate', data);
    } else {
      console.log(`⚠️ Warning: Received ICE candidate with no room designation from ${socket.id}`);
    }
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});


// Add a clean API endpoint for your Agent Dashboard to fetch waiting users
app.get('/api/next-user', (req, res) => {
  if (waitingQueue.length > 0) {
    // Take the oldest waiting room out of the queue and hand it to the agent
    const nextRoom = waitingQueue.shift(); 
    return res.json({ room: nextRoom });
  }
  return res.json({ room: null, message: "No users waiting." });
});

// This endpoint handles the 'Invoke API' response block from your chatbot
app.get('/api/next-user', (req, res) => {
  if (waitingQueue.length > 0) {
    const nextSession = waitingQueue.shift(); 
    
    // MATCHING YOUR CHATBOT UI: Return the precise keys your chatbot expects
    return res.json({
      "roomId": nextSession.roomId,   // Maps to "room_xxxxxx"
      "userId": nextSession.userId,   // Maps to "test_xxxxxx"
      "status": "waiting"             // Maps to "waiting"
    });
  }

  // Fallback response if the queue is totally empty
  return res.json({ 
    "roomId": null, 
    "userId": null, 
    "status": "idle" 
  });
});

io.on('connection', (socket) => {
  // When a user taps the escalation button in Flutter, they hit this via Socket.io
  socket.on('request-human', (data) => {
    const generatedRoomId = `room_${socket.id}`;
    socket.join(generatedRoomId);
    
    // Save both the room and a userId (passed from your app or a placeholder)
    waitingQueue.push({
      roomId: generatedRoomId,
      userId: data.userId || `user_${socket.id}`
    });
    
    socket.emit('assigned-room', { room: generatedRoomId });
    console.log(`Added to queue. Room: ${generatedRoomId}`);
  });

  // ... keep your existing join, offer, answer, and ice-candidate blocks below
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});