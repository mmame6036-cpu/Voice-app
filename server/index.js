const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

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

// --- FIREBASE ADMIN INITIALIZATION ---
const secretPath = fs.existsSync('/etc/secrets/serviceAccountKey.json')
  ? '/etc/secrets/serviceAccountKey.json'
  : path.join(__dirname, 'serviceAccountKey.json');

try {
  const serviceAccount = JSON.parse(fs.readFileSync(secretPath, 'utf8'));

  if (getApps().length === 0) {
    initializeApp({
      credential: cert(serviceAccount)
    });
  }
  console.log('Firebase Admin initialized successfully!');
} catch (error) {
  console.error('Firebase Admin init error:', error.message);
}

// --- AGORA CREDENTIALS ---
const APP_ID = 'd00a25d96dfc44cc866cd8f41c496b36';
const APP_CERTIFICATE = 'f612162b922c4dc4857cf5ab274c0108';

// --- FIREBASE CUSTOM TOKEN ENDPOINT ---
app.post('/auth/custom-token', async (req, res) => {
  const { identifier } = req.body;

  if (!identifier) {
    return res.status(400).json({ error: 'identifier is required' });
  }

  const cleanedId = String(identifier).replace(/[^a-zA-Z0-9_]/g, '_');
  const sanitizedUid = 'user_' + cleanedId;

  try {
    const customToken = await getAuth().createCustomToken(sanitizedUid);
    return res.json({
      success: true,
      token: customToken,
      uid: sanitizedUid
    });
  } catch (err) {
    console.error('Error creating custom token:', err);
    return res.status(500).json({ error: 'Failed to create custom token' });
  }
});

// --- AGORA RTC TOKEN ENDPOINT ---
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
    return res.json({ token: token });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to generate token' });
  }
});

app.get('/health', (req, res) => {
  res.send('Server is running smoothly with Socket.io real-time engine');
});

// --- COIN SELLER TELEBIRR WEBHOOK ---
app.post('/api/payment/telebirr-seller-webhook', async (req, res) => {
  try {
    const { sellerNumericId, amountBirr, telebirrTxnId } = req.body;

    if (!sellerNumericId || !amountBirr) {
      return res.status(400).json({ error: 'sellerNumericId and amountBirr are required' });
    }

    const firestore = getFirestore();
    const usersRef = firestore.collection('users');
    const sellerQuery = await usersRef.where('numericId', '==', parseInt(sellerNumericId, 10)).limit(1).get();

    if (sellerQuery.empty) {
      return res.status(404).json({ error: 'Seller account not found' });
    }

    const sellerDoc = sellerQuery.docs[0];
    const sellerData = sellerDoc.data();

    // Only accounts marked as seller are allowed
    if (sellerData.role !== 'seller') {
      return res.status(403).json({ error: 'Unauthorized: Only designated Coin Sellers can recharge via Telebirr' });
    }

    // Rate: 1 ETB = 700 Coins (Adjustable)
    const coinsToAdd = Math.floor(amountBirr * 700);

await sellerDoc.ref.update({
      coins: FieldValue.increment(coinsToAdd),
      lastRechargeMethod: 'Telebirr',
      lastTxnId: telebirrTxnId || 'N/A',
      updatedAt: FieldValue.serverTimestamp(),
    });

    return res.json({
      success: true,
      message: Recharged ${coinsToAdd} coins for seller ${sellerNumericId},
      newCoinsAdded: coinsToAdd
    });
  } catch (error) {
    console.error('Telebirr Seller Webhook Error:', error);
    return res.status(500).json({ error: 'Internal server error processing Telebirr payment' });
  }
});

// ==========================================
// --- SOCKET.IO REAL-TIME LOGIC ---
// ==========================================

const activeRooms = {};

io.on('connection', (socket) => {
  console.log([Socket] Connected: ${socket.id});

  // 1. Join room
  socket.on('join_room', ({ roomId, userName, hostName }) => {
    socket.join(roomId);
    socket.roomId = roomId;
    socket.userName = userName;

    if (!activeRooms[roomId]) {
      activeRooms[roomId] = {
        seats: Array(30).fill(null),
        seatGifts: Array(30).fill(0),
      };
      if (hostName) {
        activeRooms[roomId].seats[0] = hostName;
      }
    }

    socket.emit('room_state_sync', {
      seats: activeRooms[roomId].seats,
      seatGifts: activeRooms[roomId].seatGifts,
    });

    io.to(roomId).emit('chat_message_received', {
      sender: 'System',
      message: ${userName} joined the room.,
      isSystem: true,
    });
  });

  // 2. Seat action
  socket.on('seat_action', ({ roomId, seatIndex, userName, isLeaving }) => {
    if (!activeRooms[roomId]) return;

    if (isLeaving) {
      if (activeRooms[roomId].seats[seatIndex] === userName) {
        activeRooms[roomId].seats[seatIndex] = null;
      }
    } else {
      activeRooms[roomId].seats[seatIndex] = userName;
    }

    io.to(roomId).emit('seat_state_updated', {
      seats: activeRooms[roomId].seats,
    });
  });

  // 3. Send gift broadcast
  socket.on('send_gift', ({ roomId, senderName, targetSeatIndex, giftName, giftCost, giftAsset }) => {
    if (!activeRooms[roomId]) return;

    activeRooms[roomId].seatGifts[targetSeatIndex] =
      (activeRooms[roomId].seatGifts[targetSeatIndex] || 0) + giftCost;

    io.to(roomId).emit('gift_broadcast', {
      senderName,
      targetSeatIndex,
      giftName,
      giftCost,
      giftAsset,
      seatGifts: activeRooms[roomId].seatGifts,
    });
  });

  // 4. Send chat
  socket.on('send_chat', ({ roomId, sender, message }) => {
    io.to(roomId).emit('chat_message_received', {
      sender,
      message,
      isSystem: false,
    });
  });

  socket.on('disconnect', () => {
    console.log([Socket] Disconnected: ${socket.id});
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(Server running on port ${PORT} (HTTP & Socket.io Ready));
});
