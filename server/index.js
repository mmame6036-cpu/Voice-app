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

app.get('/ping', (req, res) => {
  res.status(200).send('pong');
});

app.get('/rtcToken', (req, res) => {
  const channelName = req.query.channelName;
  const uid = parseInt(req.query.uid, 10);
  const roleType = req.query.role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  if (!channelName || isNaN(uid)) {
    return res.status(400).json({ error: 'channelName and numeric uid are required' });
  }

  const expirationTimeInSeconds = 86400;
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

const roomStates = {};

io.on('connection', (socket) => {
  console.log('User connected: ' + socket.id);

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

    socket.emit('room_state_sync', {
      seats: roomStates[roomId].seats
    });

    console.log(userName + ' joined room: ' + roomId);
  });

  socket.on('seat_action', (data) => {
    const { roomId, seatIndex, userName, isLeaving } = data;

    if (roomStates[roomId] && seatIndex >= 0 && seatIndex < 30) {
      if (isLeaving) {
        roomStates[roomId].seats[seatIndex] = null;
      } else {
        for (let i = 0; i < 30; i++) {
          if (roomStates[roomId].seats[i] === userName) {
            roomStates[roomId].seats[i] = null;
          }
        }
        roomStates[roomId].seats[seatIndex] = userName;
      }

      io.to(roomId).emit('seat_state_updated', {
        seatIndex: seatIndex,
        userName: isLeaving ? null : userName,
        seats: roomStates[roomId].seats
      });
    }
  });

  socket.on('send_gift', (data) => {
    if (data.roomId) {
      io.to(data.roomId).emit('gift_broadcast', data);
    }
  });

  socket.on('send_chat', (data) => {
    if (data.roomId) {
      io.to(data.roomId).emit('chat_message_received', data);
    }
  });

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
    console.log('User disconnected: ' + socket.id);
  });
});

const
