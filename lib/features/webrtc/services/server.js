const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow connections from your Flutter app
    methods: ["GET", "POST"]
  }
});

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  // Join a specific room (e.g., "room-123")
  socket.on('join', (roomName) => {
    socket.join(roomName);
    console.log(`User ${socket.id} joined room: ${roomName}`);
  });

  // Relay SDP Offer
  socket.on('offer', (data) => {
    // Sends the offer to everyone in the room EXCEPT the sender
    socket.to(data.room).emit('offer', data);
  });

  // Relay SDP Answer
  socket.on('answer', (data) => {
    socket.to(data.room).emit('answer', data);
  });

  // Relay ICE Candidates
  socket.on('ice-candidate', (data) => {
    socket.to(data.room).emit('ice-candidate', data);
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});
