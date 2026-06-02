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

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});