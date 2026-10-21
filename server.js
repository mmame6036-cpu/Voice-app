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
const Agency = require('./models/Agency');
const AgencyHost = require('./models/AgencyHost');
const UserTask = require('./models/UserTask');

// Core Routes
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const agencyRoutes = require('./routes/agency');
const taskRoutes = require('./routes/tasks');

// Room Settings Modular Routes (10 Isolated Modules)
const roomCoverRoutes = require('./routes/room_cover');
const roomIdRoutes = require('./routes/room_id');
const roomNameRoutes = require('./routes/room_name');
const roomDescriptionRoutes = require('./routes/room_description');
const roomTypeRoutes = require('./routes/room_type');
const roomBackgroundRoutes = require('./routes/room_background');
const roomPermissionsRoutes = require('./routes/room_permissions');
const roomSeatsRoutes = require('./routes/room_seats');
const roomMicModeRoutes = require('./routes/room_mic_mode');
const roomBlacklistRoutes = require('./routes/room_blacklist');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.set('io', io);

// Health check route
app.get('/', (req, res) => {
  res.status(200).send('Nile Voice Server is Live and Active');
});

// Agora Dynamic Token Generator
const AGORA_APP_ID = process.env.AGORA_APP_ID ? process.env.AGORA_APP_ID : '1523b6d3b8144281a1a21f28bbbd7fef';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE ? process.env.AGORA_APP_CERTIFICATE : 'a8a098e8e7bc432d8b5c57a7a4f27657';

const handleTokenGeneration = (req, res) => {
  try {
    const rawChannel = req.query.channelName ? req.query.channelName : '1001';
    const channelName = String(rawChannel).trim();
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

// MongoDB Database Connection
const MONGO_URI = process.env.MONGO_URI ? process.env.MONGO_URI : 'mongodb+srv://Kedir:euyEPW1wNL1V9u8D@cluster0.mdtjtlb.mongodb.net/nilevoice?retryWrites=true&w=majority&appName=Cluster0';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('MongoDB Connected Successfully');
  })
  .catch((err) => {
    console.error('MongoDB Connection Error:', err);
  });

// Schemas & Models
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
  invitedBy: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});
const User = mongoose.model('User', userSchema);

const luckyPoolSchema = new mongoose.Schema({
  poolName: { type: String, default: 'lucky_pool', unique: true },
  balance: { type: Number, default: 50000 },
  totalIn: { type: Number, default: 0 },
  totalOut: { type: Number, default: 0 }
});
const LuckyPool = mongoose.model('LuckyPool', luckyPoolSchema);

const messageSchema = new mongoose.Schema({
  senderId: { type: String, required: true },
  receiverId: { type: String, required: true },
  text: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});
const Message = mongoose.model('Message', messageSchema);

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

// Mount Modular Routes
app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/agency', agencyRoutes);
app.use('/api/tasks', taskRoutes);

app.use('/api/room-cover', roomCoverRoutes);
app.use('/api/room-id', roomIdRoutes);
app.use('/api/room-name', roomNameRoutes);
app.use('/api/room-description', roomDescriptionRoutes);
app.use('/api/room-type', roomTypeRoutes);
app.use('/api/room-background', roomBackgroundRoutes);
app.use('/api/room-permissions', roomPermissionsRoutes);
app.use('/api/room-seats', roomSeatsRoutes);
app.use('/api/room-mic-mode', roomMicModeRoutes);
app.use('/api/room-blacklist', roomBlacklistRoutes);

// Payment Requests
app.post('/api/recharge-request', async (req, res) => {
  try {
    const { userId, userName, paymentMethod, txId, amountCoins, pricePaid } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'Missing user ID' });
    }
    if (!txId) {
      return res.status(400).json({ success: false, message: 'Missing transaction ID' });
    }
    if (!amountCoins) {
      return res.status(400).json({ success: false, message: 'Missing coin amount' });
    }

    const existingTx = await Payment.findOne({ txId: String(txId).trim() });
    if (existingTx) {
      return res.status(400).json({ success: false, message: 'Transaction ID already exists' });
    }

    const newPayment = new Payment({
      userId: String(userId),
      userName: userName ? userName : 'User',
      paymentMethod: paymentMethod,
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

app.get('/api/admin/pending-payments', async (req, res) => {
  try {
    const pendings = await Payment.find({ status: 'pending' }).sort({ createdAt: -1 });
    return res.json({ success: true, data: pendings });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

app.post('/api/admin/approve-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

const payment = await Payment.findById(paymentId);
    if (!payment) {
      return res.status(400).json({ success: false, message: 'Invalid payment record' });
    }
    if (payment.status !== 'pending') {
      return res.status(400).json({ success: false, message: 'Already processed payment' });
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
      description: 'Wholesale Recharge via ' + payment.paymentMethod + ' (TxID: ' + payment.txId + ')'
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

// Admin Toggle Agent
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
      message: 'Agent status updated to ' + user.isAgent,
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

// Agent Transfer Coins
app.post('/api/wallet/agent-transfer-coins', async (req, res) => {
  try {
    const { agentId, targetUserId, amountCoins } = req.body;
    const coinsToTransfer = Number(amountCoins);

    if (!agentId) {
      return res.status(400).json({ success: false, message: 'Agent ID is required' });
    }
    if (!targetUserId) {
      return res.status(400).json({ success: false, message: 'Target user ID is required' });
    }
    if (!coinsToTransfer) {
      return res.status(400).json({ success: false, message: 'Invalid coin amount' });
    }
    if (coinsToTransfer <= 0) {
      return res.status(400).json({ success: false, message: 'Transfer amount must be greater than zero' });
    }

    const agent = await User.findOne({ userId: String(agentId).trim() });
    if (!agent) {
      return res.status(403).json({ success: false, message: 'Agent not found' });
    }
    if (!agent.isAgent) {
      return res.status(403).json({ success: false, message: 'Unauthorized. You are not a registered Agent.' });
    }

    if (agent.coins < coinsToTransfer) {
      return res.status(400).json({ success: false, message: 'Insufficient agent coin balance' });
    }

    const recipient = await User.findOne({ userId: String(targetUserId).trim() });
    if (!recipient) {
      return res.status(404).json({ success: false, message: 'Recipient user not found' });
    }

    agent.coins -= coinsToTransfer;
    recipient.coins += coinsToTransfer;

    await agent.save();
    await recipient.save();

    await Transaction.create({
      userId: agent.userId,
      type: 'agent_sale',
      amount: -coinsToTransfer,
      balanceAfter: agent.coins,
      description: 'Sold ' + coinsToTransfer + ' coins to User ' + recipient.userId
    });

    await Transaction.create({
      userId: recipient.userId,
      type: 'agent_purchase',
      amount: coinsToTransfer,
      balanceAfter: recipient.coins,
      description: 'Received ' + coinsToTransfer + ' coins from Agent ' + agent.userId
    });

return res.json({
      success: true,
      message: 'Successfully transferred ' + coinsToTransfer + ' coins to User ' + recipient.userId,
      agentCoins: agent.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Room Creation
app.post('/api/rooms/create', async (req, res) => {
  try {
    const { title, category, hostId, hostName } = req.body;
    const randomRoom = Math.floor(1000 + Math.random() * 9000).toString();
    const roomId = req.body.roomId ? req.body.roomId : randomRoom;

    let room = await Room.findOne({ roomId: String(roomId) });
    if (!room) {
      const defaultTitle = hostName ? (hostName + "'s Room") : 'Live Room';

      room = new Room({
        roomId: String(roomId),
        title: title ? title : defaultTitle,
        category: category ? category : 'Chat',
        hostId: hostId,
        hostName: hostName,
      });
      await room.save();
    }
    res.json({ success: true, room: room });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/rooms', async (req, res) => {
  try {
    const rooms = await Room.find().sort({ createdAt: -1 });
    res.json({ success: true, rooms: rooms });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Helper function to assign next sequential ID (Starts at 1000)
async function getNextUserId(isOwner = false) {
  if (isOwner) return '1000';

  let counter = await Counter.findOne({ id: 'user_id' });
  if (!counter) {
    // Check if user 1000 already exists
    const ownerExists = await User.findOne({ userId: '1000' });
    const startSeq = ownerExists ? 1001 : 1000;
    counter = await Counter.create({ id: 'user_id', seq: startSeq });
    return String(counter.seq);
  }

  counter = await Counter.findOneAndUpdate(
    { id: 'user_id' },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );
  return String(counter.seq);
}

// Register User (Sequential Auto-Increment + Referral)
app.post('/api/register-user', async (req, res) => {
  try {
    const { deviceId, name, isOwner, inviterId } = req.body;

    if (deviceId) {
      let existingUser = await User.findOne({ deviceId: deviceId });
      if (existingUser) {
        if (existingUser.userId === '1000') {
          existingUser.coins = 10000000;
          await existingUser.save();
        }
        return res.json({ success: true, user: existingUser });
      }
    }

    const assignedId = await getNextUserId(isOwner === true);
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
      isFrozen: false,
      invitedBy: inviterId ? String(inviterId).trim() : ''
    });

    await newUser.save();

    // Reward Inviter
    if (inviterId) {
      const inviter = await User.findOne({ userId: String(inviterId).trim() });
      if (inviter) {
        inviter.coins += 500;
        await inviter.save();

        await Transaction.create({
          userId: inviter.userId,
          type: 'referral_bonus',
          amount: 500,
          balanceAfter: inviter.coins,
          description: 'Referral Bonus for inviting User ' + assignedId
        });
      }
    }

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

// Google Auth (Sequential Auto-Increment + Referral)
app.post('/api/auth/google', async (req, res) => {
  try {
    const { googleId, email, name, avatar, inviterId } = req.body;

if (!googleId) {
      return res.status(400).json({ success: false, message: 'Google ID is required' });
    }

    let user = await User.findOne({
      $or: [{ deviceId: googleId }, { userId: googleId }]
    });

    if (user) {
      if (user.userId === '1000') {
        user.coins = 10000000;
        await user.save();
      }
      return res.json({ success: true, user: user, isNewUser: false });
    }

    const assignedId = await getNextUserId(false);
    const initialCoins = (assignedId === '1000') ? 10000000 : 1000;

    user = new User({
      userId: assignedId,
      name: name ? name : ('User_' + assignedId),
      deviceId: googleId,
      avatar: avatar ? avatar : '',
      coins: initialCoins,
      points: 0,
      isAgent: (assignedId === '1000'),
      isFrozen: false,
      invitedBy: inviterId ? String(inviterId).trim() : ''
    });

    await user.save();

    // Reward Inviter
    if (inviterId) {
      const inviter = await User.findOne({ userId: String(inviterId).trim() });
      if (inviter) {
        inviter.coins += 500;
        await inviter.save();

        await Transaction.create({
          userId: inviter.userId,
          type: 'referral_bonus',
          amount: 500,
          balanceAfter: inviter.coins,
          description: 'Referral Bonus for inviting User ' + assignedId
        });
      }
    }

    await Transaction.create({
      userId: assignedId,
      type: 'recharge',
      amount: initialCoins,
      balanceAfter: initialCoins,
      description: 'Google Sign-up Welcome Bonus'
    });

    return res.json({ success: true, user: user, isNewUser: true });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Referral Stats Route
app.get('/api/referral/my-team', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'Missing userId' });
    }

    const invitedMembers = await User.find({ invitedBy: String(userId).trim() })
      .select('userId name avatar createdAt')
      .sort({ createdAt: -1 });

    return res.json({
      success: true,
      totalInvited: invitedMembers.length,
      members: invitedMembers
    });
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

// Socket.io Real-time
const roomSeatsState = {};
const seatJoinTimes = {};
const roomUserStayTimes = {};

const getTodayString = () => {
  const now = new Date();
  return now.toISOString().split('T')[0];
};

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

if (senderId) {
        const today = getTodayString();
        await UserTask.findOneAndUpdate(
          { userId: String(senderId), date: today },
          { $inc: { messagesSentCount: 1 } },
          { upsert: true }
        );
      }

      io.to(String(receiverId)).emit('receive_direct_message', newMsg);
      socket.emit('message_sent', newMsg);
    } catch (e) {
      console.error('Message error:', e);
    }
  });

  socket.on('call_user', async (data) => {
    try {
      const { callerId, callerName, targetUserId } = data;
      const caller = await User.findOne({ userId: String(callerId) });

      if (!caller) {
        socket.emit('call_error', { message: 'Caller not found' });
        return;
      }
      if (caller.coins < 20) {
        socket.emit('call_error', { message: 'Insufficient coins. You need at least 20 coins to make a call.' });
        return;
      }

      const defaultCallerName = callerName ? callerName : ('User ' + callerId);
      const privateChannel = 'call_' + callerId + '_' + targetUserId + '_' + Date.now();

      io.to(String(targetUserId)).emit('incoming_call', {
        callerId: callerId,
        callerName: defaultCallerName,
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
      reason: reason ? reason : 'Call rejected'
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
      const cost = Number(amount) ? Number(amount) : 20;

      const caller = await User.findOne({ userId: String(callerId) });
      if (!caller) return;

      if (caller.coins < cost) {
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
        description: '1-Minute Private Voice Call to User ' + receiverId
      });

      socket.emit('call_coin_deducted', { remainingCoins: caller.coins });
    } catch (err) {
      console.error('Call coin deduct error:', err);
    }
  });

  socket.on('join_room', (data) => {
    let roomId = '1001';
    if (data.room) roomId = String(data.room);
    if (data.roomId) roomId = String(data.roomId);

    socket.currentRoom = roomId;
    socket.join(roomId);

    if (socket.userId) {
      roomUserStayTimes[socket.userId] = Date.now();
    }

    if (roomSeatsState[roomId]) {
      socket.emit('sync_room_seats', roomSeatsState[roomId]);
    }
  });

  socket.on('chair_action', async (data) => {
    let roomId = '1001';
    if (data.room) roomId = String(data.room);
    if (data.roomId) roomId = String(data.roomId);

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
      seatJoinTimes[String(data.userId)] = Date.now();
    } else if (action === 'leave') {
      delete roomSeatsState[roomId][chairIndex];

      const joinTime = seatJoinTimes[String(data.userId)];
      if (joinTime) {
        const durationMinutes = Math.floor((Date.now() - joinTime) / 60000);
        delete seatJoinTimes[String(data.userId)];

        if (durationMinutes >= 1) {
          const durationHours = parseFloat((durationMinutes / 60).toFixed(2));
          await AgencyHost.findOneAndUpdate(
            { userId: String(data.userId), status: 'active' },
            { 
              $inc: { validHours: durationHours },
              $set: { validDays: 1 } 
            }
          );
        }
      }
    }

    const payload = Object.assign({}, data, { room: roomId, roomId: roomId });
    io.to(roomId).emit('chair_action', payload);
  });

  socket.on('chair_speaking', (data) => {
    let roomId = '1001';
    if (data.room) roomId = String(data.room);
    if (data.roomId) roomId = String(data.roomId);
    io.to(roomId).emit('chair_speaking', data);
  });

  socket.on('chat_message', (data) => {
    let roomId = '1001';
    if (data.room) roomId = String(data.room);
    if (data.roomId) roomId = String(data.roomId);
    io.to(roomId).emit('chat_message', data);
  });

  // Gift Engine with Sustainable Server Lucky Pool Logic
  socket.on('gift_sent', async (data) => {
    try {
      const { senderId, receiverId, giftPrice, room, giftName, count, isLucky } = data;
      let roomId = '1001';
      if (room) roomId = String(room);
      if (data.roomId) roomId = String(data.roomId);

      const giftCount = Number(count) ? Number(count) : 1;
      const unitPrice = Number(giftPrice) ? Number(giftPrice) : 0;
      const totalCost = unitPrice * giftCount;

      const sender = await User.findOne({ userId: String(senderId) });
      if (!sender) return;
      if (sender.coins < totalCost) {
        socket.emit('gift_error', { message: 'Insufficient coins balance' });
        return;
      }

      sender.coins -= totalCost;
      await sender.save();

      // Track Daily Gift Sent Task
      if (senderId) {
        const today = getTodayString();
        await UserTask.findOneAndUpdate(
          { userId: String(senderId), date: today },
          { $inc: { giftSentCount: 1 } },
          { upsert: true }
        );
      }

      // 70% to Receiver Diamonds/Points
      const diamondReward = Math.round(totalCost * 0.70);
      if (receiverId) {
        await User.findOneAndUpdate(
          { userId: String(receiverId) },
          { $inc: { points: diamondReward } }
        );

        const hostAgencyRecord = await AgencyHost.findOne({ 
          userId: String(receiverId), 
          status: 'active' 
        });

        if (hostAgencyRecord) {
          hostAgencyRecord.currentMonthPoints = (hostAgencyRecord.currentMonthPoints ? hostAgencyRecord.currentMonthPoints : 0) + diamondReward;
          await hostAgencyRecord.save();

          const parentAgency = await Agency.findOne({ agencyId: hostAgencyRecord.agencyId });
          if (parentAgency) {
            const rate = parentAgency.commissionRate ? parentAgency.commissionRate : 10;
            const agencyCommissionPoints = Math.floor(diamondReward * (rate / 100));

            parentAgency.balancePoints = (parentAgency.balancePoints ? parentAgency.balancePoints : 0) + agencyCommissionPoints;
            parentAgency.totalEarnings = (parentAgency.totalEarnings ? parentAgency.totalEarnings : 0) + agencyCommissionPoints;
            await parentAgency.save();
          }
        }
      }

      const defaultGift = giftName ? giftName : 'Gift';
      const defaultTarget = receiverId ? receiverId : 'Room';

await Transaction.create({
        userId: String(senderId),
        type: 'gift_sent',
        amount: totalCost,
        balanceAfter: sender.coins,
        description: 'Sent ' + defaultGift + ' x' + giftCount + ' to ' + defaultTarget
      });

      // House Edge Pool Logic for Lucky Multipliers
      let wonMultiplier = 0;
      let wonCoins = 0;

      if (isLucky) {
        const poolTax = Math.round(totalCost * 0.20);
        let pool = await LuckyPool.findOneAndUpdate(
          { poolName: 'lucky_pool' },
          { $inc: { balance: poolTax, totalIn: poolTax } },
          { new: true, upsert: true }
        );

        const rand = Math.floor(Math.random() * 100);
        let targetMultiplier = 0;

        if (rand < 2) {
          targetMultiplier = 250;
        } else if (rand < 7) {
          targetMultiplier = 50;
        } else if (rand < 20) {
          targetMultiplier = 25;
        }

        if (targetMultiplier > 0) {
          const potentialWin = unitPrice * targetMultiplier;
          if (pool && pool.balance >= potentialWin) {
            wonMultiplier = targetMultiplier;
            wonCoins = potentialWin;

            pool.balance -= wonCoins;
            pool.totalOut += wonCoins;
            await pool.save();

            sender.coins += wonCoins;
            await sender.save();

            await Transaction.create({
              userId: String(senderId),
              type: 'lucky_win',
              amount: wonCoins,
              balanceAfter: sender.coins,
              description: 'Won ' + wonMultiplier + 'x lucky prize on ' + defaultGift
            });

            const bannerText = sender.name + ' so lucky and won ' + wonMultiplier + 'x the prize (' + wonCoins + ' Coins)!';
            io.to(roomId).emit('chat_message', {
              room: roomId,
              roomId: roomId,
              sender: 'Jackpot',
              text: '🎉 ' + bannerText
            });

            io.to(roomId).emit('jackpot_win_broadcast', {
              senderName: sender.name,
              multiplier: wonMultiplier,
              coins: wonCoins,
              giftName: defaultGift
            });
          }
        }
      }

      const payload = Object.assign({}, data, {
        senderCoins: sender.coins,
        wonMultiplier: wonMultiplier,
        wonCoins: wonCoins,
        diamondReward: diamondReward
      });
      io.to(roomId).emit('gift_sent', payload);
    } catch (e) {
      console.error('Gift transaction error:', e);
    }
  });

  socket.on('game_win', (data) => {
    io.emit('game_win_broadcast', data);
  });

  socket.on('disconnect', async () => {
    if (socket.userId && roomUserStayTimes[socket.userId]) {
      const stayMs = Date.now() - roomUserStayTimes[socket.userId];
      const stayMinutes = Math.floor(stayMs / 60000);
      delete roomUserStayTimes[socket.userId];

      if (stayMinutes >= 1) {
        const today = getTodayString();
        await UserTask.findOneAndUpdate(
          { userId: String(socket.userId), date: today },
          { $inc: { stayDurationMinutes: stayMinutes } },
          { upsert: true }
        );
      }
    }

    if (socket.currentRoom) {
      if (socket.userId) {
        const roomId = socket.currentRoom;
        if (roomSeatsState[roomId]) {
          for (const idx in roomSeatsState[roomId]) {
            if (roomSeatsState[roomId][idx].userId === socket.userId) {
              delete roomSeatsState[roomId][idx];
              delete seatJoinTimes[String(socket.userId)];
              const defaultName = socket.userName ? socket.userName : 'User';
              io.to(roomId).emit('chair_action', {
                action: 'leave',
                chairIndex: parseInt(idx),
                userId: socket.userId,
                userName: defaultName,
                room: roomId,
                roomId: roomId
              });
            }
          }
        }
      }
    }
  });
});

const PORT = process.env.PORT ? process.env.PORT : 10000;
server.listen(PORT, '0.0.0.0', () => {
  console.log('Server running on port ' + PORT);
});
