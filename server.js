const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// 1. Health check route
app.get('/', (req, res) => {
  res.status(200).send('Nile Voice Server is Live and Active');
});

// 2. MongoDB Database Connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://Kedir:euyEPW1wNL1V9u8D@cluster0.mdtjtlb.mongodb.net/nilevoice?retryWrites=true&w=majority&appName=Cluster0';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('MongoDB Connected Successfully');
  })
  .catch((err) => {
    console.error('MongoDB Connection Error:', err);
  });

// --- MongoDB Schemas & Models ---
const counterSchema = new mongoose.Schema({
  id: { type: String, required: true, default: 'user_id' },
  seq: { type: Number, default: 1000 }
});
const Counter = mongoose.model('Counter', counterSchema);

const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  name: { type: String, default: 'User' },
  deviceId: { type: String, unique: true },
  avatar: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});
const User = mongoose.model('User', userSchema);

const messageSchema = new mongoose.Schema({
  senderId: { type: String, required: true },
  receiverId: { type: String, required: true },
  text: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});
const Message = mongoose.model('Message', messageSchema);

// --- REST APIs ---

// User registration (Assigns ID starting from 1000)
app.post('/api/register-user', async (req, res) => {
  try {
    const { deviceId, name, isOwner } = req.body;

    let existingUser = await User.findOne({ deviceId: deviceId });
    if (existingUser) {
      return res.json({ success: true, user: existingUser });
    }

    let assignedId = '1000';
    if (isOwner) {
      assignedId = '1000';
    } else {
      let counter = await Counter.findOneAndUpdate(
        { id: 'user_id' },
        { $inc: { seq: 1 } },
        { new: true, upsert: true }
      );
      assignedId = String(counter.seq);
    }

    const defaultName = name ? name : ('User_' + assignedId);
    const defaultDevice = deviceId ? deviceId : ('dev_' + Date.now());

    const newUser = new User({
      userId: assignedId,
      name: defaultName,
      deviceId: defaultDevice
    });

    await newUser.save();
    return res.json({ success: true, user: newUser });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Search user by ID
app.get('/api/search-user', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }
    const user = await User.findOne({ userId: String(userId).trim() });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    return res.json({ success: true, user: user });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// Fetch direct messaging chat history
app.get('/api/chat-history', async (req, res) => {
  try {
    const { user1, user2 } = req.query;
    const messages = await Message.find({
      $or: [
        { senderId: user1, receiverId: user2 },
        { senderId: user2, receiverId: user1 }
      ]
    }).sort({ timestamp: 1 });
    return res.json({ success: true, messages: messages });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// --- Agora Dynamic Token Generator ---
const AGORA_APP_ID = process.env.AGORA_APP_ID || '1523b6d3b8144281a1a21f28bbbd7fef';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || 'A8a098e8e7bc432d8b5c57a7a4f27657';

const handleTokenGeneration = (req, res) => {
  try {
    const channelName = req.query.channelName || '1001';
    const uid = req.query.uid ? parseInt(req.query.uid) : 0;
    const role = RtcRole.PUBLISHER;
    const expireTime = 3600 * 24; // Valid for 24 hours
    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTime + expireTime;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpireTime
    );

    return res.json({ 
      success: true, 
      token: token, 
      channelName: channelName, 
      uid: uid 
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// Supports both routes for client requests
app.get('/api/get-token', handleTokenGeneration);
app.get('/rtc-token', handleTokenGeneration);

// --- Socket.io Real-time Communication ---
io.on('connection', (socket) => {
  // Join private communication channel
  socket.on('user_connected', (userId) => {
    if (userId) {
      socket.join(String(userId));
      console.log('User joined private channel: ' + userId);
    }
  });

  // Peer-to-peer direct text messaging
  socket.on('send_direct_message', async (data) => {
    try {
      const { senderId, receiverId, text } = data;
      const newMsg = new Message({
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        timestamp: new Date()
      });
      await newMsg.save();

      io.to(String(receiverId)).emit('receive_direct_message', newMsg);
      socket.emit('message_sent', newMsg);
    } catch (e) {
      console.error('Message error:', e);
    }
  });

  // Voice room events
  socket.on('join_room', (data) => {
    const roomId = data.room || '1001';
    socket.join(roomId);
  });

  socket.on('chair_action', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('chair_action', data);
  });

  socket.on('chair_speaking', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('chair_speaking', data);
  });

  socket.on('chat_message', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('chat_message', data);
  });

  socket.on('gift_sent', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('gift_sent', data);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
