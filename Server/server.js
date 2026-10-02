const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

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

// የናይል ቮይስ ዳታቤዝ (In-Memory Central Storage)
const db = {
  users: {
    "1000": {
      id: "1000",
      name: "KEDIR (Super Owner)",
      role: "owner",
      coins: 50000,
      points: 0,
      biometricVerified: true,
      backpack: ["special_id_1000"]
    },
    "1001": {
      id: "1001",
      name: "Guest User",
      role: "user",
      coins: 100,
      points: 0,
      biometricVerified: false,
      backpack: []
    }
  },
  rooms: {
    "nile_room_1": {
      id: "nile_room_1",
      title: "🌊 Nile VIP Grand Lounge",
      hostId: "1000",
      speakers: []
    }
  }
};

// መነሻ ገጽ
app.get('/', (req, res) => {
  res.send('🌊 Nile Voice Backend Engine is Running Live!');
});

// የተጠቃሚ መረጃ ማረጋገጫ API
app.get('/api/user/:id', (req, res) => {
  const user = db.users[req.params.id];
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }
  res.json({ success: true, user });
});

// ባዮሜትሪክስ ማረጋገጫ API
app.post('/api/user/verify-biometrics', (req, res) => {
  const { userId, verificationType } = req.body;
  if (!db.users[userId]) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }
  db.users[userId].biometricVerified = true;
  res.json({
    success: true,
    message: ${verificationType} verification successful! Access granted.,
    user: db.users[userId]
  });
});

// የስቶር ግዢ ትዕዛዝ ማከናወኛ
app.post('/api/store/buy', (req, res) => {
  const { userId, itemId, price } = req.body;
  const user = db.users[userId];

  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  if (!user.biometricVerified) {
    return res.status(403).json({
      success: false,
      message: 'Access Denied: Biometric verification is strictly required.'
    });
  }

  if (user.coins < price) {
    return res.status(400).json({
      success: false,
      message: 'Insufficient Coins! Please recharge your wallet.'
    });
  }

  user.coins -= price;
  user.backpack.push(itemId);

  io.emit('wallet_updated', { userId: user.id, newBalance: user.coins });

  res.json({
    success: true,
    message: 'Item purchased successfully!',
    newBalance: user.coins,
    backpack: user.backpack
  });
});

// የቀጥታ ግንኙነት (Socket.io)
io.on('connection', (socket) => {
  console.log('⚡ Connected to Nile Voice Socket:', socket.id);

  socket.on('join_room', ({ roomId, userId }) => {
    socket.join(roomId);
    io.to(roomId).emit('user_joined_room', { userId });
  });

  socket.on('send_gift', ({ fromUserId, toUserId, roomId, giftId, coinValue }) => {
    const sender = db.users[fromUserId];
    const receiver = db.users[toUserId];

    if (sender && sender.coins >= coinValue) {
      sender.coins -= coinValue;
      if (receiver) {
        receiver.points += coinValue;
      }

      io.to(roomId).emit('gift_received', {
        fromUser: sender.name,
        giftId: giftId,
        coins: coinValue
      });
    }
  });

  socket.on('disconnect', () => {
    console.log('🔌 Client disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(🌊 Nile Voice Server is live on port ${PORT});
});
