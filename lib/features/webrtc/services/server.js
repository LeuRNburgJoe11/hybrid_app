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

// Health check endpoint — prevents Render free-tier cold starts from
// stalling the WebRTC handshake. Flutter app pings this before joining.
app.get('/health', (req, res) => res.json({ status: 'ok' }));

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  // BUG 4 FIX: Flutter emits 'join' with a plain roomId string.
  // Original server.js event was also 'join' — this was correct —
  // but Flutter was emitting 'join-room' with an object. Now unified:
  // server listens for 'join', Flutter emits 'join' with plain roomId string.
  socket.on('join', (roomName) => {
    socket.join(roomName);
    console.log(`User ${socket.id} joined room: ${roomName}`);
  });

  // BUG 5 FIX: Relay using data.room to match what Flutter now emits.
  // Original Flutter code emitted { roomId: '...' } but server.js used
  // data.room for socket.to() routing — so offers/answers were never relayed.
  // Both sides now use the key 'room'.
  socket.on('offer', (data) => {
    console.log(`Relaying offer in room: ${data.room}`);
    socket.to(data.room).emit('offer', data);
  });

  socket.on('answer', (data) => {
    console.log(`Relaying answer in room: ${data.room}`);
    socket.to(data.room).emit('answer', data);
  });

  // ICE candidates also use 'room' key for consistency
  socket.on('ice-candidate', (data) => {
    socket.to(data.room || data.roomId).emit('ice-candidate', data);
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});
