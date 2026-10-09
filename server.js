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

// 1. የሰርቨር ጤና ማረጋገጫ
app.get('/', (req, res) => {
  res.status(200).send('Nile Voice Server is Live & Active! 🚀');
});

// 2. MongoDB ግንኙነት
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://Kedir:euyEPW1wNL1V9u8D@cluster0.mdtjtlb.mongodb.net/nilevoice?retryWrites=true&w=majority&appName=Cluster0';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB በስኬት ተገናኝቷል!');
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
  });

// --- MongoDB Schemas & Models ---
// ተከታታይ ID ቆጣሪ (Counter)
const counterSchema = new mongoose.Schema({
  id: { type: String, required: true, default: 'user_id' },
  seq: { type: Number, default: 1000 }
});
const Counter = mongoose.model('Counter', counterSchema);

// የተጠቃሚ ሞዴል
const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  name: { type: String, default: 'User' },
  deviceId: { type: String, unique: true },
  avatar: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});
const User = mongoose.model('User', userSchema);

// የቴክስት መልዕክቶች ሞዴል (Direct Messages)
const messageSchema = new mongoose.Schema({
  senderId: { type: String, required: true },
  receiverId: { type: String, required: true },
  text: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});
const Message = mongoose.model('Message', messageSchema);

// --- REST APIs ---

// አዲስ ተጠቃሚ ሲመጣ ID መስጫ (1000 የባለቤቱ፣ ከዛ 1001, 1002...)
app.post('/api/register-user', async (req, res) => {
  try {
    const { deviceId, name, isOwner } = req.body;

    // ቀድሞ የተመዘገበ ከሆነ ያለውን ID መመለስ
    let existingUser = await User.findOne({ deviceId });
    if (existingUser) {
      return res.json({ success: true, user: existingUser });
    }

    let assignedId;
    if (isOwner) {
      assignedId = '1000'; // የአንተ ስልክ ቋሚ 1000
    } else {
      let counter = await Counter.findOneAndUpdate(
        { id: 'user_id' },
        { $inc: { seq: 1 } },
        { new: true, upsert: true }
      );
      assignedId = counter.seq.toString();
    }

    const newUser = new User({
      userId: assignedId,
      name: name || User_${assignedId},
      deviceId: deviceId || dev_${Date.now()}
    });

    await newUser.save();
    return res.json({ success: true, user: newUser });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ተጠቃሚን በአይዲ (ID) መፈለጊያ
app.get('/api/search-user', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }
    const user = await User.findOne({ userId: userId.trim() });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    return res.json({ success: true, user });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// የቀድሞ ቴክስቶችን መጫኛ (Load Chat History)
app.get('/api/chat-history', async (req, res) => {
  try {
    const { user1, user2 } = req.query;
    const messages = await Message.find({
      $or: [
        { senderId: user1, receiverId: user2 },
        { senderId: user2, receiverId: user1 }
      ]
    }).sort({ timestamp: 1 });
    return res.json({ success: true, messages });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// --- Agora Token ---
const AGORA_APP_ID = process.env.AGORA_APP_ID || '21091aff01114a66b580ce15b0f1b642';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '150ff1ae871e4d80a9e51092d00524a5';

app.get('/rtc-token', (req, res) => {
  try {
    const channelName = req.query.channelName || 'room_1001';
    const uid = req.query.uid ? parseInt(req.query.uid) : 0;
    const role = RtcRole.PUBLISHER;
    const expireTime = 3600 * 24;
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

    return res.json({ token, channelName, uid });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// --- Socket.io Events ---
io.on('connection', (socket) => {
  // ተጠቃሚው በራሱ ID የተሰየመ የግል ቻናል ይቀላቀላል
  socket.on('user_connected', (userId) => {
    if (userId) {
      socket.join(userId.toString());
      console.log(👤 User joined private channel: ${userId});
    }
  });

  // የግል ቴክስት መላላኪያ (P2P Direct Message)
  socket.on('send_direct_message', async (data) => {
    try {
      const { senderId, receiverId, text } = data;
      const newMsg = new Message({
        senderId,
        receiverId,
        text,
        timestamp: new Date()
      });
      await newMsg.save();

      // ለተቀባዩ በግል ቻናሉ ይላካል
      io.to(receiverId.toString()).emit('receive_direct_message', newMsg);
      // ለላኪው ማረጋገጫ ይመለሳል
      socket.emit('message_sent', newMsg);
    } catch (e) {
      console.error('Message error:', e);
    }
  });

  // የድምፅ ክፍል ሶኬቶች (Room 1001)
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
  console.log("Server running on port " + PORT);
});
