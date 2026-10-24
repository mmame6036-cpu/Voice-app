const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTTP and Socket.io Server Setup
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Socket.io Real-time Handlers
io.on('connection', (socket) => {
  console.log('User connected to socket:', socket.id);

  socket.on('join_room', (roomName) => {
    socket.join(roomName);
    console.log(Socket ${socket.id} joined room: ${roomName});
  });

  socket.on('send_message', (data) => {
    socket.to(data.room).emit('receive_message', {
      user: data.user,
      text: data.text
    });
  });

  socket.on('send_gift', (data) => {
    socket.to(data.room).emit('receive_gift', {
      sender: data.sender,
      emoji: data.emoji,
      giftName: data.giftName
    });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Core Routes
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const agencyRoutes = require('./routes/agency');
const taskRoutes = require('./routes/tasks');
const hostRoutes = require('./routes/host');

app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/agency', agencyRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/host', hostRoutes);

app.get('/', (req, res) => {
  res.send('Server is running smoothly');
});

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('Database Connected Successfully');
    server.listen(PORT, () => {
      console.log('Server running on port ' + PORT);
    });
  })
  .catch((err) => {
    console.error('Database connection error:', err);
  });
