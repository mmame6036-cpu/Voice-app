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
// ============================================================================
// 7. CoinSeller Checkout + Admin Dashboard Endpoints (Firebase Firestore)
// ============================================================================
let firestoreDb = null;
let firestoreFieldValue = null;

try {
  const admin = require('firebase-admin');
  if (!admin.apps.length) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(sa)
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault()
      });
    }
  }
  if (admin.apps.length) {
    firestoreDb = admin.firestore();
    firestoreFieldValue = admin.firestore.FieldValue;
  }
} catch (fbErr) {
  console.log('Firebase Admin optional init note: ' + fbErr.message);
}

// Create order from CoinSellerScreen
app.post('/api/create-order', async (req, res) => {
  try {
    const body = req.body || {};
    const uid = String(body.userUid || body.uid || '').trim();
    const numericId = Number(body.targetNumericId || body.userNumericId || body.numericId || 0) || 0;
    const coins = Number(body.coins || 0) || 0;
    const usdAmount = Number(body.usdAmount || body.amount || body.priceUsd || 0) || 0;
    const now = new Date();
    const stamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`;
    const orderRef = `${stamp}${numericId}${String(now.getMilliseconds()).padStart(4, '0')}`;
    const binancePayId = process.env.BINANCE_PAY_ID || '1059643208';

    pendingOrders.set(orderRef, {
      userUid: uid,
      userNumericId: numericId,
      targetNumericId: numericId,
      coins,
      priceUsd: usdAmount,
      status: 'PENDING',
      createdAt: Date.now()
    });

    if (firestoreDb) {
      await firestoreDb.collection('coin_recharges').doc(orderRef).set({
        orderRef,
        uid,
        sellerNumericId: String(numericId),
        numericId,
        coins,
        usdAmount,
        paymentMethod: 'Binance Pay (USDT)',
        currency: 'USDT',
        credited: false,
        status: 'PENDING',
        timestamp: firestoreFieldValue.serverTimestamp()
      }, { merge: true });
    }

    return res.status(200).json({
      success: true,
      orderRef,
      binancePayId,
      checkoutUrl: ''
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Verify payment status from CoinSellerScreen
app.post('/api/verify-payment', async (req, res) => {
  try {
    const body = req.body || {};
    const orderRef = String(body.orderRef || body.txnId || '').trim();
    if (!orderRef) {
      return res.status(400).json({ verified: false, message: 'orderRef is required' });
    }

    const memOrder = pendingOrders.get(orderRef);
    if (memOrder && (memOrder.status === 'PAID' || memOrder.status === 'VERIFIED_SUCCESS')) {
      return res.status(200).json({ verified: true, credited: false });
    }

    if (firestoreDb) {
      const snap = await firestoreDb.collection('coin_recharges').doc(orderRef).get();
      if (snap.exists) {
        const d = snap.data() || {};
        const st = String(d.status || '').toUpperCase();
        if (st === 'VERIFIED_SUCCESS' || st === 'PAID' || st === 'APPROVED' || st === 'COMPLETED') {
          return res.status(200).json({
            verified: true,
            credited: d.credited === true
          });
        }
      }
    }

    return res.status(200).json({
      verified: false,
      message: 'Payment not received yet'
    });
  } catch (e) {
    return res.status(500).json({ verified: false, error: e.message });
  }
});

// Admin Dashboard Overview
app.get('/api/admin/overview', async (req, res) => {
  try {
    if (!firestoreDb) {
      return res.status(200).json({
        stats: { totalRevenueUsd: 0, totalUserCoins: 0, totalUnpaidPoints: 0, totalUsers: 0, totalAgencies: 0 },
        userOrders: [],
        sellerOrders: [],
        withdrawals: [],
        users: [],
        agencies: []
      });
    }

    const [usersSnap, agenciesSnap, sellerRechargesSnap, userRechargesSnap, reqsSnap, wdrSnap] = await Promise.all([
      firestoreDb.collection('users').get(),
      firestoreDb.collection('agencies').get(),
      firestoreDb.collection('coin_recharges').get(),
      firestoreDb.collection('recharge_orders').get().catch(() => ({ docs: [] })),
      firestoreDb.collection('recharge_requests').get().catch(() => ({ docs: [] })),
      firestoreDb.collection('withdrawals').get().catch(() => ({ docs: [] }))
    ]);

    const users = [];
    let totalUserCoins = 0;
    let totalUnpaidPoints = 0;
    usersSnap.forEach((doc) => {
      const d = doc.data() || {};
      const coins = Number(d.coins || 0) || 0;
      const pts = Number(d.points || 0) || 0;
      totalUserCoins += coins;
      totalUnpaidPoints += pts;
      users.push({
        uid: doc.id,
        name: d.name || d.displayName || 'User',
        numericId: d.numericId || '',
        coins,
        points: pts,
        isFaceVerified: d.isFaceVerified === true,
        isBanned: d.isBanned === true,
        isAgent: d.isAgent === true || String(d.agencyId || '').trim().length > 0
      });
    });

    const agencies = [];
    agenciesSnap.forEach((doc) => {
      const d = doc.data() || {};
      agencies.push({
        id: doc.id,
        agencyId: d.agencyId || doc.id,
        name: d.name || d.agencyName || 'Agency',
        ownerName: d.ownerName || '',
        ownerNumericId: d.ownerNumericId || '',
        ownerUid: d.ownerUid || '',
        phone: d.phone || '',
        country: d.country || '',
        status: d.status || 'APPROVED',
        totalHosts: Number(d.totalHosts || 0) || 0,
        withdrawnCommissionPoints: Number(d.withdrawnCommissionPoints || 0) || 0
      });
    });

    const sellerOrders = [];
    let totalRevenueUsd = 0;
    sellerRechargesSnap.forEach((doc) => {
      const d = doc.data() || {};
      const st = String(d.status || 'PENDING').toUpperCase();
      const usd = Number(d.usdAmount || d.amount || 0) || 0;
      if (st === 'VERIFIED_SUCCESS' || st === 'PAID' || st === 'APPROVED' || st === 'COMPLETED') {
        totalRevenueUsd += usd;
      }
      sellerOrders.push({
        orderRef: d.orderRef || doc.id,
        sellerName: d.sellerName || '',
        paymentMethod: d.paymentMethod || 'Binance Pay (USDT)',
        coins: Number(d.coins || 0) || 0,
        usdAmount: usd,
        binanceTxId: d.binanceTxId || d.transactionId || '',
        proofScreenshot: d.proofScreenshot || d.screenshotUrl || '',
        status: st
      });
    });

    const userOrders = [];
    userRechargesSnap.forEach((doc) => {
      const d = doc.data() || {};
      userOrders.push({
        orderRef: d.orderRef || doc.id,
        numericId: d.numericId || d.userNumericId || '',
        coins: Number(d.coins || 0) || 0,
        usdAmount: Number(d.usdAmount || d.amount || 0) || 0,
        binanceTxId: d.binanceTxId || d.transactionId || '',
        proofScreenshot: d.proofScreenshot || d.screenshotUrl || '',
        status: String(d.status || 'PENDING').toUpperCase()
      });
    });

    reqsSnap.forEach((doc) => {
      const d = doc.data() || {};
      const ref = d.orderRef || doc.id;
      const existsInSeller = sellerOrders.some((x) => x.orderRef === ref);
      const existsInUser = userOrders.some((x) => x.orderRef === ref);
      if (!existsInSeller && !existsInUser) {
        userOrders.push({
          orderRef: ref,
          numericId: d.userNumericId || d.sellerNumericId || '',
          coins: Number(d.coins || 0) || 0,
          usdAmount: Number(d.usdAmount || d.amount || 0) || 0,
          binanceTxId: d.binanceTxId || d.transactionId || '',
          proofScreenshot: d.proofScreenshot || d.screenshotUrl || '',
          status: String(d.status || 'PENDING').toUpperCase()
        });
      }
    });

    const withdrawals = [];
    wdrSnap.forEach((doc) => {
      const d = doc.data() || {};
      withdrawals.push({
        id: doc.id,
        userName: d.userName || d.name || 'Host',
        method: d.method || '',
        account: d.account || '',
        points: Number(d.points || 0) || 0,
        usdAmount: Number(d.usdAmount || 0) || 0,
        status: String(d.status || 'PENDING').toUpperCase()
      });
    });

    return res.status(200).json({
      stats: {
        totalRevenueUsd,
        totalUserCoins,
        totalUnpaidPoints,
        totalUsers: users.length,
        totalAgencies: agencies.length
      },
      userOrders,
      sellerOrders,
      withdrawals,
      users,
      agencies
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Approve / Reject Seller Order
app.post('/api/admin/seller-order', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { orderRef, action } = req.body || {};
    const actUpper = String(action || '').toUpperCase();
    const refDoc = firestoreDb.collection('coin_recharges').doc(String(orderRef));

    await firestoreDb.runTransaction(async (tx) => {
      const snap = await tx.get(refDoc);
      if (!snap.exists) throw new Error('Order not found');
      const d = snap.data() || {};
      if (actUpper === 'APPROVE') {
        if (d.credited !== true && d.uid) {
          const coins = Number(d.coins || 0) || 0;
          const usd = Number(d.usdAmount || d.amount || 0) || 0;
          tx.set(firestoreDb.collection('users').doc(String(d.uid)), {
            coins: firestoreFieldValue.increment(coins),
            maxSingleRechargeUsd: usd
          }, { merge: true });
        }
        tx.set(refDoc, {
          status: 'VERIFIED_SUCCESS',
          credited: true,
          verifiedAt: firestoreFieldValue.serverTimestamp()
        }, { merge: true });
      } else if (actUpper === 'REJECT') {
        tx.set(refDoc, {
          status: 'REJECTED',
          rejectedAt: firestoreFieldValue.serverTimestamp()
        }, { merge: true });
      }
    });

    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Approve / Reject User Order
app.post('/api/admin/user-order', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { orderRef, action } = req.body || {};
    const actUpper = String(action || '').toUpperCase();
    const refDoc = firestoreDb.collection('recharge_orders').doc(String(orderRef));
    const reqDoc = firestoreDb.collection('recharge_requests').doc(String(orderRef));

    const snap = await refDoc.get();
    const fallbackSnap = snap.exists ? snap : await reqDoc.get();
    if (!fallbackSnap.exists) return res.status(404).json({ error: 'Order not found' });

    const d = fallbackSnap.data() || {};
    if (actUpper === 'APPROVE') {
      if (d.credited !== true && (d.uid || d.userUid)) {
        const targetUid = String(d.uid || d.userUid);
        const coins = Number(d.coins || 0) || 0;
        await firestoreDb.collection('users').doc(targetUid).set({
          coins: firestoreFieldValue.increment(coins)
        }, { merge: true });
      }
      await Promise.all([
        refDoc.set({ status: 'APPROVED', credited: true }, { merge: true }),
        reqDoc.set({ status: 'APPROVED', credited: true }, { merge: true })
      ]);
    } else if (actUpper === 'REJECT') {
      await Promise.all([
        refDoc.set({ status: 'REJECTED' }, { merge: true }),
        reqDoc.set({ status: 'REJECTED' }, { merge: true })
      ]);
    }
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Withdrawal Paid / Reject
app.post('/api/admin/withdrawal', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { requestId, action } = req.body || {};
    const st = String(action || '').toUpperCase() === 'PAID' ? 'PAID' : 'REJECTED';
    await firestoreDb.collection('withdrawals').doc(String(requestId)).set({
      status: st,
      processedAt: firestoreFieldValue.serverTimestamp()
    }, { merge: true });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// User Control (+Coins, Face, Ban)
app.post('/api/admin/user-control', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { uid, addCoins, toggleFace, toggleBan } = req.body || {};
    if (!uid) return res.status(400).json({ error: 'uid required' });
    const uRef = firestoreDb.collection('users').doc(String(uid));
    const snap = await uRef.get();
    const cur = snap.exists ? (snap.data() || {}) : {};
    const patch = {};

    if (typeof addCoins === 'number' && !isNaN(addCoins) && addCoins !== 0) {
      patch.coins = firestoreFieldValue.increment(addCoins);
    }
    if (toggleFace) {
      patch.isFaceVerified = !(cur.isFaceVerified === true);
    }
    if (toggleBan) {
      patch.isBanned = !(cur.isBanned === true);
    }
    await uRef.set(patch, { merge: true });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Create Agency / Promote User to Agent
app.post('/api/admin/create-agency', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { agencyId, agencyName, ownerNumericId, ownerUid } = req.body || {};
    const id = String(agencyId || ownerNumericId || '').trim();
    if (!id) return res.status(400).json({ error: 'agencyId required' });

    let resolvedOwnerUid = String(ownerUid || '').trim();
    const numId = Number(ownerNumericId || id);
    if (!resolvedOwnerUid && !isNaN(numId) && numId > 0) {
      const q = await firestoreDb.collection('users').where('numericId', '==', numId).limit(1).get();
      if (!q.empty) resolvedOwnerUid = q.docs[0].id;
    }

    await firestoreDb.collection('agencies').doc(id).set({
      agencyId: id,
      name: String(agencyName || `Agency ${id}`),
      ownerNumericId: !isNaN(numId) ? numId : (ownerNumericId || ''),
      ownerUid: resolvedOwnerUid,
      status: 'APPROVED',
      updatedAt: firestoreFieldValue.serverTimestamp()
    }, { merge: true });

    if (resolvedOwnerUid) {
      await firestoreDb.collection('users').doc(resolvedOwnerUid).set({
        isAgent: true,
        role: 'agent',
        agencyId: id,
        agencyName: String(agencyName || `Agency ${id}`)
      }, { merge: true });
    }
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Approve / Reject Agency Request
app.post('/api/admin/respond-agency', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { agencyId, approve } = req.body || {};
    const id = String(agencyId || '').trim();
    const agRef = firestoreDb.collection('agencies').doc(id);
    const snap = await agRef.get();
    const d = snap.exists ? (snap.data() || {}) : {};
    const newStatus = approve ? 'APPROVED' : 'REJECTED';

    await agRef.set({ status: newStatus }, { merge: true });
    if (d.ownerUid) {
      await firestoreDb.collection('users').doc(String(d.ownerUid)).set({
        isAgent: Boolean(approve),
        role: approve ? 'agent' : 'user',
        agencyId: approve ? id : '',
        agencyName: approve ? (d.name || '') : ''
      }, { merge: true });
    }
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Remove Agent Status
app.post('/api/admin/remove-agency', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { agencyId, ownerUid } = req.body || {};
    const id = String(agencyId || '').trim();
    let targetUid = String(ownerUid || '').trim();

    if (id) {
      const agRef = firestoreDb.collection('agencies').doc(id);
      const snap = await agRef.get();
      if (snap.exists) {
        const d = snap.data() || {};
        if (!targetUid && d.ownerUid) targetUid = String(d.ownerUid);
        await agRef.set({ status: 'REMOVED' }, { merge: true });
      }
    }

    if (targetUid) {
      await firestoreDb.collection('users').doc(targetUid).set({
        isAgent: false,
        role: 'user',
        agencyId: '',
        agencyName: ''
      }, { merge: true });
    }
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Permanently Delete Agency
app.post('/api/admin/delete-agency', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { agencyId } = req.body || {};
    const id = String(agencyId || '').trim();
    if (!id) return res.status(400).json({ error: 'agencyId required' });

    const agRef = firestoreDb.collection('agencies').doc(id);
    const snap = await agRef.get();
    const d = snap.exists ? (snap.data() || {}) : {};
    await agRef.delete();
    await firestoreDb.collection('agency_requests').doc(id).delete().catch(() => {});

    if (d.ownerUid) {
      await firestoreDb.collection('users').doc(String(d.ownerUid)).set({
        isAgent: false,
        role: 'user',
        agencyId: '',
        agencyName: ''
      }, { merge: true });
    }
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Permanently Delete User
app.post('/api/admin/delete-user', async (req, res) => {
  try {
    if (!firestoreDb) return res.status(500).json({ error: 'Firestore not configured' });
    const { uid } = req.body || {};
    const targetUid = String(uid || '').trim();
    if (!targetUid) return res.status(400).json({ error: 'uid required' });

    await firestoreDb.collection('users').doc(targetUid).delete();
    await firestoreDb.collection('hosts').doc(targetUid).delete().catch(() => {});
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});
