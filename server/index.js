const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const APP_ID = 'd00a25d96dfc44cc866cd8f41c496b36';
const APP_CERTIFICATE = 'f612162b922c4dc4857cf5ab274c0108';

// ሰርቨሩ ነቅቶ እንዲቆይ (Health Check / Self-ping)
app.get('/ping', (req, res) => {
  res.status(200).send('pong');
});

// 1. Agora Token አመንጪ
app.get('/rtcToken', (req, res) => {
  const channelName = req.query.channelName;
  const uid = parseInt(req.query.uid, 10);
  const roleType = req.query.role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  if (!channelName || isNaN(uid)) {
    return res.status(400).json({ error: 'channelName and numeric uid are required' });
  }

  const expirationTimeInSeconds = 86400; // 24 ሰዓት
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      roleType,
      privilegeExpiredTs
    );
    return res.json({ token });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to generate token' });
  }
});

// 2. እውነተኛ የቀጥታ ወንበር እና ስጦታ ስርጭት (Socket.io Real-Time Engine)
const roomStates = {};

io.on('connection', (socket) => {
  console.log(User connected: ${socket.id});

  // ተጠቃሚው ወደ ሩም ሲገባ
  socket.on('join_room', (data) => {
    const roomId = data.roomId;
    const userName = data.userName;

    socket.join(roomId);
    socket.roomId = roomId;
    socket.userName = userName;

    if (!roomStates[roomId]) {
      roomStates[roomId] = {
        seats: Array(30).fill(null)
      };
    }

    // አዲሱ ተጠቃሚ የክፍሉን የወንበር ሁኔታ ያገኛል
    socket.emit('room_state_sync', {
      seats: roomStates[roomId].seats
    });

    console.log(${userName} joined room: ${roomId});
  });

  // ወንበር ሲያዝ ወይም ሲለቀቅ
  socket.on('seat_action', (data) => {
    const { roomId, seatIndex, userName, isLeaving } = data;

    if (roomStates[roomId] && seatIndex >= 0 && seatIndex < 30) {
      if (isLeaving) {
        roomStates[roomId].seats[seatIndex] = null;
      } else {
        // የቀድሞ ወንበሩን ያጸዳል
        for (let i = 0; i < 30; i++) {
          if (roomStates[roomId].seats[i] === userName) {
            roomStates[roomId].seats[i] = null;
          }
        }
        roomStates[roomId].seats[seatIndex] = userName;
      }

      // በክፍሉ ውስጥ ላሉ ተጠቃሚዎች በሙሉ (ለሌላውም ስልክ) ወዲያውኑ ያስተላልፋል
      io.to(roomId).emit('seat_state_updated', {
        seatIndex: seatIndex,
        userName: isLeaving ? null : userName,
        seats: roomStates[roomId].seats
      });
    }
  });

  // ስጦታ ሲላክ በክፍሉ ላሉ በሙሉ በአንድ ጊዜ ይሰራጫል
  socket.on('send_gift', (data) => {
    if (data.roomId) {
      io.to(data.roomId).emit('gift_broadcast', data);
    }
  });

  // ቻት ሲላክ
  socket.on('send_chat', (data) => {
    if (data.roomId) {
      io.to(data.roomId).emit('chat_message_received', data);
    }
  });

  // ተጠቃሚው ሲወጣ ወይም አፑ ሲዘጋ ወንበሩን ነፃ ያደርጋል
  socket.on('disconnect', () => {
    const roomId = socket.roomId;
    const userName = socket.userName;

    if (roomId && userName && roomStates[roomId]) {
      for (let i = 0; i < 30; i++) {
        if (roomStates[roomId].seats[i] === userName) {
          roomStates[roomId].seats[i] = null;
          io.to(roomId).emit('seat_state_updated', {
            seatIndex: i,
            userName: null,
            seats: roomStates[roomId].seats
          });
        }
      }
    }
    console.log(User disconnected: ${socket.id});
  });
});

// 3. Render እንዳይተኛ የሚያደርግ አውቶማቲክ ንቃት (Self-Ping)
const SERVER_URL = 'https://nile-token-server.onrender.com/ping';
setInterval(() => {
  fetch(SERVER_URL)
    .then(() => console.log('Keep-alive ping sent successfully'))
    .catch((err) => console.log('Keep-alive ping error:', err.message));
}, 600000); // በየ 10 ደቂቃው ራሱን ይጠራል

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(Server listening on port ${PORT});
});
