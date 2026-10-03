require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI)
  .then(() => console.log('✅ MongoDB connected successfully!'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

// Basic Route
app.get('/', (req, res) => {
  res.send('🚀 Nile Voice Server is running successfully!');
});

// Socket.io for Real-time Voice / Chat Rooms
io.on('connection', (socket) => {
  console.log('⚡ A user connected:', socket.id);

  // ክፍል ውስጥ ሲገቡ
  socket.on('join_room', (roomId) => {
    socket.join(roomId);
    console.log(User ${socket.id} joined room: ${roomId});
    socket.to(roomId).emit('user_joined', socket.id);
  });

  // ከመስመር ሲወጡ
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(📡 Server listening on port ${PORT});
});
