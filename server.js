const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
const { Server } = require('socket.io');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const mongoose = require('mongoose');

// Models
const Room = require('./models/Room');
const Transaction = require('./models/Transaction');

// Routes
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.set('io', io);

// 1. Health check route
app.get('/', (req, res) => {
  res.status(200).send('Nile Voice Server is Live and Active');
});

// --- Agora Dynamic Token Generator ---
const AGORA_APP_ID = process.env.AGORA_APP_ID || '1523b6d3b8144281a1a21f28bbbd7fef';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || 'a8a098e8e7bc432d8b5c57a7a4f27657';

const handleTokenGeneration = (req, res) => {
  try {
    const channelName = String(req.query.channelName || '1001').trim();
    const role = RtcRole.PUBLISHER;
    const expireTime = 3600 * 24 * 30;
    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTime + expireTime;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      0, 
      role,
      privilegeExpireTime,
      privilegeExpireTime
    );

    return res.json({ 
      success: true, 
      token: token, 
      channelName: channelName 
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

app.get('/api/get-token', handleTokenGeneration);
app.get('/rtc-token', handleTokenGeneration);

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
  coins: { type: Number, default: 1000 },
  points: { type: Number, default: 0 },
  isAgent: { type: Boolean, default: false },
  isFrozen: { type: Boolean, default: false },
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

// Payment Request Schema (For Wholesale Coin Seller Recharge)
const paymentSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  userName: { type: String, default: 'User' },
  paymentMethod: { type: String, enum: ['Telebirr', 'Binance', 'Binance Pay'], required: true },
  txId: { type: String, required: true, unique: true },
  amountCoins: { type: Number, required: true },
  pricePaid: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now }
});
const Payment = mongoose.model('Payment', paymentSchema);

// --- Modular Routes ---
app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);

// --- Agent Management Endpoints ---

// 1. Admin: Toggle or Set Agent Role
app.post('/api/admin/toggle-agent', async (req, res) => {
  try {
    const { userId, isAgent } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }

    const user = await User.findOne({ userId: String(userId).trim() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isAgent = (typeof isAgent === 'boolean') ? isAgent : !user.isAgent;
    await user.save();

    return res.json({
      success: true,
      message: Agent status updated to ${user.isAgent},
      user: {
        userId: user.userId,
        name: user.name,
        isAgent: user.isAgent,
        coins: user.coins
      }
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Agent: Transfer Coins to Users (Coin Selling Flow)
app.post('/api/wallet/agent-transfer-coins', async (req, res) => {
  try {
    const { agentId, targetUserId, amountCoins } = req.body;
    const coinsToTransfer = Number(amountCoins);

    if (!agentId  !targetUserId  !coinsToTransfer || coinsToTransfer <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid transfer details' });
    }

    const agent = await User.findOne({ userId: String(agentId).trim() });
    if (!agent || !agent.isAgent) {
      return res.status(403).json({ success: false, message: 'Unauthorized. You are not a registered Agent.' });
    }

    if (agent.coins < coinsToTransfer) {
      return res.status(400).json({ success: false, message: 'Insufficient agent coin balance' });
    }

    const recipient = await User.findOne({ userId: String(targetUserId).trim() });
    if (!recipient) {
      return res.status(404).json({ success: false, message: 'Recipient user not found' });
    }

    // Deduct from agent, add to recipient
    agent.coins -= coinsToTransfer;
    recipient.coins += coinsToTransfer;

    await agent.save();
    await recipient.save();

    // Log Transactions
    await Transaction.create({
      userId: agent.userId,
      type: 'agent_sale',
      amount: -coinsToTransfer,
      balanceAfter: agent.coins,
      description: Sold ${coinsToTransfer} coins to User ${recipient.userId}
    });

    await Transaction.create({
      userId: recipient.userId,
      type: 'agent_purchase',
      amount: coinsToTransfer,
      balanceAfter: recipient.coins,
      description: Received ${coinsToTransfer} coins from Agent ${agent.userId}
    });

    return res.json({
      success: true,
      message: Successfully transferred ${coinsToTransfer} coins to User ${recipient.userId},
      agentCoins: agent.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// --- Payment & Recharge Endpoints ---
app.post('/api/recharge-request', async (req, res) => {
  try {
    const { userId, userName, paymentMethod, txId, amountCoins, pricePaid } = req.body;

    if (!userId  !txId  !amountCoins) {
      return res.status(400).json({ success: false, message: 'Missing required payment fields' });
    }

    const existingTx = await Payment.findOne({ txId: String(txId).trim() });
    if (existingTx) {
      return res.status(400).json({ success: false, message: 'ይህ የግብይት ቁጥር (TxID) ቀድሞ ገብቷል!' });
    }

    const newPayment = new Payment({
      userId: String(userId),
      userName: userName || 'User',
      paymentMethod,
      txId: String(txId).trim(),
      amountCoins: Number(amountCoins),
      pricePaid: String(pricePaid),
      status: 'pending'
    });

    await newPayment.save();
    return res.json({ success: true, message: 'Recharge request submitted successfully' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Admin: View Pending Payments
app.get('/api/admin/pending-payments', async (req, res) => {
  try {
    const pendings = await Payment.find({ status: 'pending' }).sort({ createdAt: -1 });
    return res.json({ success: true, data: pendings });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Admin: Approve Payment & Add Coins
app.post('/api/admin/approve-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

    const payment = await Payment.findById(paymentId);
    if (!payment || payment.status !== 'pending') {
      return res.status(400).json({ success: false, message: 'Invalid or already processed payment' });
    }

    const user = await User.findOneAndUpdate(
      { userId: payment.userId },
      { $inc: { coins: payment.amountCoins } },
      { new: true }
    );

    await Transaction.create({
      userId: payment.userId,
      type: 'recharge',
      amount: payment.amountCoins,
      balanceAfter: user ? user.coins : 0,
      description: Wholesale Recharge via ${payment.paymentMethod} (TxID: ${payment.txId})
    });

    payment.status = 'approved';
    await payment.save();

    return res.json({
      success: true,
      message: 'Payment approved and coins added successfully',
      updatedCoins: user ? user.coins : null
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// --- Room Management Endpoints ---
app.post('/api/rooms/create', async (req, res) => {
  try {
    const { title, category, hostId, hostName } = req.body;
    const roomId = req.body.roomId || Math.floor(1000 + Math.random() * 9000).toString();

    let room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      room = new Room({
        roomId: String(roomId),
        title: title || ${hostName}'s Room,
        category: category || 'Chat',
        hostId,
        hostName,
      });
      await room.save();
    }
    res.json({ success: true, room });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/rooms', async (req, res) => {
  try {
    const rooms = await Room.find().sort({ createdAt: -1 });
    res.json({ success: true, rooms });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// --- User Registration & Search Endpoints ---
app.post('/api/register-user', async (req, res) => {
  try {
    const { deviceId, name, isOwner } = req.body;

    let existingUser = await User.findOne({ deviceId: deviceId });
    if (existingUser) {
      if (existingUser.userId === '1000') {
        existingUser.coins = 10000000;
        await existingUser.save();
      }
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
    const initialCoins = (assignedId === '1000') ? 10000000 : 1000;

    const newUser = new User({
      userId: assignedId,
      name: defaultName,
      deviceId: defaultDevice,
      coins: initialCoins,
      points: 0,
      isAgent: (assignedId === '1000'),
      isFrozen: false
    });

    await newUser.save();

    await Transaction.create({
      userId: assignedId,
      type: 'recharge',
      amount: initialCoins,
      balanceAfter: initialCoins,
      description: 'Welcome Bonus'
    });

    return res.json({ success: true, user: newUser });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// --- Google Authentication Endpoint ---
app.post('/api/auth/google', async (req, res) => {
  try {
    const { googleId, email, name, avatar } = req.body;

if (!googleId) {
      return res.status(400).json({ success: false, message: 'Google ID is required' });
    }

    let user = await User.findOne({ $or: [{ deviceId: googleId }, { userId: googleId }] });

    if (user) {
      if (user.userId === '1000') {
        user.coins = 10000000;
        await user.save();
      }
      return res.json({ success: true, user, isNewUser: false });
    }

    let counter = await Counter.findOneAndUpdate(
      { id: 'user_id' },
      { $inc: { seq: 1 } },
      { new: true, upsert: true }
    );
    const assignedId = String(counter.seq);
    const initialCoins = (assignedId === '1000') ? 10000000 : 1000;

    user = new User({
      userId: assignedId,
      name: name || User_${assignedId},
      deviceId: googleId,
      avatar: avatar || '',
      coins: initialCoins,
      points: 0,
      isAgent: (assignedId === '1000'),
      isFrozen: false
    });

    await user.save();

    await Transaction.create({
      userId: assignedId,
      type: 'recharge',
      amount: initialCoins,
      balanceAfter: initialCoins,
      description: 'Google Sign-up Welcome Bonus'
    });

    return res.json({ success: true, user, isNewUser: true });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

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

// --- Socket.io Real-time Communication ---
const roomSeatsState = {};

io.on('connection', (socket) => {
  socket.on('user_connected', (userId) => {
    if (userId) {
      socket.userId = String(userId);
      socket.join(String(userId));
      console.log('User joined private channel: ' + userId);
    }
  });

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

  // 1-on-1 Private Call
  socket.on('call_user', async (data) => {
    try {
      const { callerId, callerName, targetUserId } = data;
      const caller = await User.findOne({ userId: String(callerId) });

      if (!caller || caller.coins < 20) {
        socket.emit('call_error', { message: 'Insufficient coins. You need at least 20 coins to make a call.' });
        return;
      }

      const privateChannel = call_${callerId}_${targetUserId}_${Date.now()};

      io.to(String(targetUserId)).emit('incoming_call', {
        callerId: callerId,
        callerName: callerName || User ${callerId},
        channelName: privateChannel
      });

      socket.emit('call_ringing', { channelName: privateChannel });
    } catch (err) {
      console.error('Call User Error:', err);
    }
  });

  socket.on('accept_call', (data) => {
    const { callerId, channelName, receiverId } = data;
    io.to(String(callerId)).emit('call_accepted', {
      channelName: channelName,
      receiverId: receiverId
    });
  });

socket.on('reject_call', (data) => {
    const { callerId, reason } = data;
    io.to(String(callerId)).emit('call_rejected', {
      reason: reason || 'Call rejected'
    });
  });

  socket.on('end_call', (data) => {
    const { targetUserId } = data;
    if (targetUserId) {
      io.to(String(targetUserId)).emit('call_ended');
    }
  });

  socket.on('call_deduct_coins', async (data) => {
    try {
      const { callerId, receiverId, amount } = data;
      const cost = Number(amount) || 20;

      const caller = await User.findOne({ userId: String(callerId) });
      if (!caller || caller.coins < cost) {
        socket.emit('call_balance_depleted', { message: 'Call ended due to low coin balance.' });
        io.to(String(receiverId)).emit('call_ended');
        return;
      }

      caller.coins -= cost;
      await caller.save();

      if (receiverId) {
        await User.findOneAndUpdate(
          { userId: String(receiverId) },
          { $inc: { points: cost } }
        );
      }

      await Transaction.create({
        userId: String(callerId),
        type: 'call_fee',
        amount: cost,
        balanceAfter: caller.coins,
        description: 1-Minute Private Voice Call to User ${receiverId}
      });

      socket.emit('call_coin_deducted', { remainingCoins: caller.coins });
    } catch (err) {
      console.error('Call coin deduct error:', err);
    }
  });

  // Audio Rooms & Streaming
  socket.on('join_room', (data) => {
    const roomId = String(data.room  data.roomId  '1001');
    socket.currentRoom = roomId;
    socket.join(roomId);

    if (roomSeatsState[roomId]) {
      socket.emit('sync_room_seats', roomSeatsState[roomId]);
    }
  });

  socket.on('chair_action', (data) => {
    const roomId = String(data.room  data.roomId  '1001');
    const chairIndex = data.chairIndex;
    const action = data.action;

    if (!roomSeatsState[roomId]) {
      roomSeatsState[roomId] = {};
    }

    if (action === 'take') {
      for (const idx in roomSeatsState[roomId]) {
        if (roomSeatsState[roomId][idx].userId === data.userId) {
          delete roomSeatsState[roomId][idx];
        }
      }
      roomSeatsState[roomId][chairIndex] = {
        userName: data.userName,
        userId: data.userId
      };
    } else if (action === 'leave') {
      delete roomSeatsState[roomId][chairIndex];
    }

    io.to(roomId).emit('chair_action', {
      ...data,
      room: roomId,
      roomId: roomId
    });
  });

  socket.on('chair_speaking', (data) => {
    const roomId = String(data.room  data.roomId  '1001');
    io.to(roomId).emit('chair_speaking', data);
  });

  socket.on('chat_message', (data) => {
    const roomId = String(data.room  data.roomId  '1001');
    io.to(roomId).emit('chat_message', data);
  });

  socket.on('gift_sent', async (data) => {
    try {
      const { senderId, receiverId, giftPrice, room, giftName } = data;
      const roomId = String(room  data.roomId  '1001');
      const cost = Number(giftPrice) || 0;

      const sender = await User.findOne({ userId: String(senderId) });
      if (!sender || sender.coins < cost) {
        socket.emit('gift_error', { message: 'Insufficient coins balance' });
        return;
      }

      sender.coins -= cost;
      await sender.save();

      if (receiverId) {
        await User.findOneAndUpdate(
          { userId: String(receiverId) },
          { $inc: { points: cost } }
        );
      }

      await Transaction.create({
        userId: String(senderId),
        type: 'gift_sent',
        amount: cost,
        balanceAfter: sender.coins,
        description: Sent ${giftName || 'Gift'} to ${receiverId || 'Room'}
      });

      io.to(roomId).emit('gift_sent', {
        ...data,
        senderCoins: sender.coins
      });
    } catch (e) {
      console.error('Gift transaction error:', e);
    }
  });

  socket.on('game_win', (data) => {
    io.emit('game_win_broadcast', data);
  });

socket.on('disconnect', () => {
    if (socket.currentRoom && socket.userId) {
      const roomId = socket.currentRoom;
      if (roomSeatsState[roomId]) {
        for (const idx in roomSeatsState[roomId]) {
          if (roomSeatsState[roomId][idx].userId === socket.userId) {
            delete roomSeatsState[roomId][idx];
            io.to(roomId).emit('chair_action', {
              action: 'leave',
              chairIndex: parseInt(idx),
              userId: socket.userId,
              userName: socket.userName || 'User',
              room: roomId,
              roomId: roomId
            });
          }
        }
      }
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
