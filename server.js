require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

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

// 3. Agora RTC Token ማመንጫ Route
const AGORA_APP_ID = process.env.AGORA_APP_ID || '21091aff01114a66b580ce15b0f1b642';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '150ff1ae871e4d80a9e51092d00524a5';

app.get('/rtc-token', (req, res) => {
  const channelName = req.query.channelName || 'NileVoiceMainRoom';
  const uid = req.query.uid ? parseInt(req.query.uid) : 0;
  const role = RtcRole.PUBLISHER;
  const expireTime = 3600 * 24; // ለ 24 ሰዓት የሚሰራ
  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpireTime
    );
    return res.json({ token, channelName });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// 4. Socket.io Real-time Engine
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

  socket.on('chat_message', (data) => {
    io.emit('chat_message', data);
  });

  socket.on('gift_sent', (data) => {
    io.emit('gift_sent', data);
  });

  socket.on('disconnect', () => {
    console.log('Socket disconnected:', socket.id);
  });
});

// 5. Start Server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
