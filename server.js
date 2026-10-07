require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// --- 1. MongoDB Database Schemas ---

// User & Wallet Schema
const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  name: { type: String, default: 'ተጠቃሚ' },
  role: { type: String, enum: ['user', 'admin', 'agent'], default: 'user' },
  isFaceVerified: { type: Boolean, default: false },
  verifiedAt: { type: String, default: '' },
  taxCycleDay: { type: Number, default: 0 },
  coins: { type: Number, default: 0 }
});
const User = mongoose.model('User', userSchema);

// Room & Seats Schema
const roomSchema = new mongoose.Schema({
  roomId: { type: String, required: true, unique: true },
  hostId: { type: String, required: true },
  roomTitle: { type: String, default: 'የቀጥታ ድምጽ ክፍል' },
  dailyTax: { type: Number, default: 20 },
  seats: [
    {
      seatIndex: Number,
      occupantId: { type: String, default: null }
    }
  ],
  createdAt: { type: Date, default: Date.now }
});
const Room = mongoose.model('Room', roomSchema);

// Coin Transaction Audit Log Schema
const transactionSchema = new mongoose.Schema({
  senderId: String,
  receiverId: String,
  amount: Number,
  type: { type: String, enum: ['admin_mint', 'transfer', 'gift', 'game_reward'] },
  timestamp: { type: Date, default: Date.now }
});
const Transaction = mongoose.model('Transaction', transactionSchema);

// --- 2. Database Connection ---
const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI)
  .then(() => console.log('✅ MongoDB connected successfully!'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

// --- 3. API Routes for Flutter App ---

app.get('/', (req, res) => {
  res.send('Nile Voice App Server & Database are running successfully!');
});

// የፊት አሻራ ማረጋገጫ API
app.post('/verify-face', async (req, res) => {
  try {
    const { userId } = req.body;
    let user = await User.findOne({ userId });
    
    if (!user) {
      user = new User({ userId });
    }

    user.isFaceVerified = true;
    user.verifiedAt = new Date().toISOString().split('T')[0];
    user.taxCycleDay = 1;
    await user.save();

    res.json({
      success: true,
      message: 'የፊት አሻራ በትክክል ጸድቋል',
      verifiedAt: user.verifiedAt
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// አዲስ ክፍል መክፈቻ API
app.post('/rooms/create', async (req, res) => {
  try {
    const { userId, roomTitle, dailyTax } = req.body;

    const newRoomId = 'room_' + Date.now();
    const defaultSeats = Array.from({ length: 8 }, (_, i) => ({
      seatIndex: i + 1,
      occupantId: null
    }));

    const newRoom = new Room({
      roomId: newRoomId,
      hostId: userId,
      roomTitle: roomTitle || 'የቀጥታ ድምጽ ክፍል',
      dailyTax: dailyTax || 20,
      seats: defaultSeats
    });

    await newRoom.save();

    res.json({
      success: true,
      message: 'ክፍሉ ተከፍቷል!',
      room: newRoom
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ክፍሎችን መመልከቻ API
app.get('/rooms', async (req, res) => {
  try {
    const rooms = await Room.find().sort({ createdAt: -1 });
    res.json({ success: true, rooms });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// አድሚን ብቻ ኮይን የሚያመነጭበት ሴኪዩር API
app.post('/admin/mint-coins', async (req, res) => {
  try {
    const { adminKey, targetUserId, amount } = req.body;

    // የአድሚን ሴኪዩሪቲ ኪይ ማረጋገጫ
    if (adminKey !== process.env.ADMIN_SECRET_KEY) {
      return res.status(403).json({ success: false, message: 'ያልተፈቀደ ሙከራ!' });
    }

let user = await User.findOne({ userId: targetUserId });
    if (!user) {
      user = new User({ userId: targetUserId, coins: 0 });
    }

    user.coins += Number(amount);
    await user.save();

    // ኦዲት ሎግ መመዝገብ
    await Transaction.create({
      senderId: 'ADMIN_SYSTEM',
      receiverId: targetUserId,
      amount: Number(amount),
      type: 'admin_mint'
    });

    res.json({ success: true, message: ${amount} ኮይን ተጨምሯል, newBalance: user.coins });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// --- 4. Socket.io Real-Time Engine (ቀጥታ ክፍል እና ወንበሮች) ---
io.on('connection', (socket) => {
  console.log('User connected to socket:', socket.id);

  socket.on('join_room', (roomId) => {
    socket.join(roomId);
    io.to(roomId).emit('user_joined', { socketId: socket.id });
  });

  // ወንበር ሲያዝ ለክፍሉ ሰዎች በሙሉ ማሳወቂያ
  socket.on('take_seat', async ({ roomId, seatIndex, userId }) => {
    try {
      const room = await Room.findOne({ roomId });
      if (room) {
        const seat = room.seats.find(s => s.seatIndex === seatIndex);
        if (seat && !seat.occupantId) {
          seat.occupantId = userId;
          await room.save();
          io.to(roomId).emit('seat_updated', { seatIndex, occupantId: userId });
        }
      }
    } catch (e) {
      console.error(e);
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Server Listen
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(Server listening on port ${PORT});
});
