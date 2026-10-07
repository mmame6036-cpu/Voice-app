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

app.use(cors());
app.use(express.json());

// 1. Database
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/voice_app';
mongoose.connect(MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.log('MongoDB error:', err.message));

// 2. Test Route
app.get('/', (req, res) => {
  res.send('Server is running perfectly!');
});

// 3. Socket.io Real-time Engine
io.on('connection', (socket) => {
  console.log('Socket connected:', socket.id);

  socket.on('join_room', (data) => {
    const roomId = (typeof data === 'object' && data.room) ? data.room : data;
    socket.join(roomId);
  });

  socket.on('chair_action', (data) => {
    console.log('Chair action:', data);
    io.emit('chair_action', data);
  });

  socket.on('disconnect', () => {
    console.log('Socket disconnected:', socket.id);
  });
});

// 4. Start Server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
