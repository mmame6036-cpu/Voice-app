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
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const APP_ID = 'd00a25d96dfc44cc866cd8f41c496b36';
const APP_CERTIFICATE = 'f612162b922c4dc4857cf5ab274c0108';

// Store pending payment orders in memory
const pendingOrders = new Map();

// 1. Health Check Endpoint
app.get('/ping', (req, res) => {
  res.status(200).send('pong');
});

// 2. Agora RTC Token Generator (Publisher and Subscriber)
app.get('/rtcToken', (req, res) => {
  const channelName = req.query.channelName;
  const uid = parseInt(req.query.uid, 10);

  let roleType = RtcRole.SUBSCRIBER;
  if (req.query.role === 'publisher') {
    roleType = RtcRole.PUBLISHER;
  }

  if (!channelName) {
    return res.status(400).json({ error: 'channelName is required' });
  }

  if (isNaN(uid)) {
    return res.status(400).json({ error: 'numeric uid is required' });
  }

  const expirationTimeInSeconds = 86400; // 24 hours
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

// 3. Binance Pay Order Creation Endpoint
app.post('/api/payment/binance-pay', (req, res) => {
  const { userUid, userNumericId, targetNumericId, coins, priceUsd, txnId } = req.body;

  if (!txnId) {
    return res.status(400).json({
      success: false,
      message: 'Missing transaction ID'
    });
  }

  if (!coins) {
    return res.status(400).json({
      success: false,
      message: 'Missing coins amount'
    });
  }

  if (!priceUsd) {
    return res.status(400).json({
      success: false,
      message: 'Missing USD price'
    });
  }

  pendingOrders.set(txnId, {
    userUid: userUid,
    userNumericId: userNumericId,
    targetNumericId: targetNumericId,
    coins: coins,
    priceUsd: priceUsd,
    status: 'PENDING',
    createdAt: Date.now()
  });

  let payId = 'YOUR_BINANCE_PAY_ID';
  if (process.env.BINANCE_PAY_ID) {
    payId = process.env.BINANCE_PAY_ID;
  }

  return res.status(200).json({
    success: true,
    status: 'PENDING',
    verified: false,
    binancePayId: payId,
    message: 'Awaiting USDT payment confirmation'
  });
});

// 4. Binance Pay Order Verification Endpoint
app.post('/api/payment/verify-binance-pay', (req, res) => {
  const { txnId } = req.body;
  const order = pendingOrders.get(txnId);

  if (!order) {
    return res.status(404).json({
      verified: false,
      message: 'Order not found or expired'
    });
  }

  if (order.status === 'PAID') {
    return res.status(200).json({
      verified: true,
      credited: false
    });
  }

  return res.status(200).json({
    verified: false,
    message: 'Payment not confirmed yet. Please wait 1 minute or contact support with Order Ref.'
  });
});

// 5. Real-Time Seat, Gift, and Chat Sync (Socket.io)
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

      let updatedUser = userName;
      if (isLeaving) {
        updatedUser = null;
      }

      io.to(roomId).emit('seat_state_updated', {
        seatIndex: seatIndex,
        userName: updatedUser,
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

// 6. Keep-Alive Self-Ping Engine (Every 10 minutes)
const SERVER_URL = 'https://nile-token-server.onrender.com/ping';
setInterval(() => {
  fetch(SERVER_URL)
    .then(() => console.log('Keep-alive ping sent successfully'))
    .catch((err) => console.log('Keep-alive ping failed: ' + err.message));
}, 600000);

let PORT = 3000;
if (process.env.PORT) {
  PORT = process.env.PORT;
}

server.listen(PORT, () => {
  console.log('Agora and Socket Server listening on port ' + PORT);
});
