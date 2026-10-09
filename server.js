const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const mongoose = require('mongoose');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// 1. የ MongoDB ዳታቤዝ ግንኙነት (24 ሰዓት ነቅቶ የሚቆይ)
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://Kedir:euyEPW1wNL1V9u8D@cluster0.mdtjtlb.mongodb.net/nilevoice?retryWrites=true&w=majority&appName=Cluster0';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB በስኬት ተገናኝቷል! ዳታቤዙ 24 ሰዓት ንቁ ነው!');
  })
  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
  });

const AGORA_APP_ID = process.env.AGORA_APP_ID || '21091aff01114a66b580ce15b0f1b642';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '150ff1ae871e4d80a9e51092d00524a5';

// 2. የድምፅ ቶከን ማመንጫ (RtcRole.PUBLISHER)
app.get('/rtc-token', (req, res) => {
  try {
    const channelName = req.query.channelName || 'room_1001';
    const uid = req.query.uid ? parseInt(req.query.uid) : 0;
    const role = RtcRole.PUBLISHER; // ድምፅ እንዲያስተላልፍ የግዴታ PUBLISHER
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

// 3. የሶኬት መረጃ ማስተላለፊያ
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
  console.log(Server running on port ${PORT});
});
