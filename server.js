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

// 1. የሰርቨር ጤና ማረጋገጫ (UptimeRobot እና Render 200 OK እንዲያገኙ)
app.get('/', (req, res) => {
  res.status(200).send('Nile Voice Server is Live & Active! 🚀');
});

// 2. የ MongoDB ዳታቤዝ ግንኙነት
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://Kedir:euyEPW1wNL1V9u8D@cluster0.mdtjtlb.mongodb.net/nilevoice?retryWrites=true&w=majority&appName=Cluster0';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB በስኬት ተገናኝቷል!');
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
  });

const AGORA_APP_ID = process.env.AGORA_APP_ID || '21091aff01114a66b580ce15b0f1b642';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '150ff1ae871e4d80a9e51092d00524a5';

// 3. የድምፅ ቶከን ማመንጫ (RtcRole.PUBLISHER)
app.get('/rtc-token', (req, res) => {
  try {
    const channelName = req.query.channelName || 'room_1001';
    const uid = req.query.uid ? parseInt(req.query.uid) : 0;
    const role = RtcRole.PUBLISHER; // ድምፅ እንዲያስተላልፍ PUBLISHER
    const expireTime = 3600 * 24; // 24 ሰዓት
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

// 4. የሶኬት መረጃ ማስተላለፊያ
io.on('connection', (socket) => {
  // ክፍል መቀላቀል
  socket.on('join_room', (data) => {
    const roomId = data.room || '1001';
    socket.join(roomId);
  });

  // ወንበር መያዝ ወይም መልቀቅ
  socket.on('chair_action', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('chair_action', data);
  });

  // ድምፅ ሲያወራ ማሳወቂያ
  socket.on('chair_speaking', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('chair_speaking', data);
  });

  // ቻት
  socket.on('chat_message', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('chat_message', data);
  });

  // ስጦታ
  socket.on('gift_sent', (data) => {
    const roomId = data.room || '1001';
    io.to(roomId).emit('gift_sent', data);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log("server running on port " + PORT);
});
