const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const firebaseApp = require('firebase-admin/app');
const firebaseFirestore = require('firebase-admin/firestore');
const FieldValue = firebaseFirestore.FieldValue;
const agoraToken = require('agora-token');
const RtcTokenBuilder = agoraToken.RtcTokenBuilder;
const RtcRole = agoraToken.RtcRole;

const app = express();
app.use(cors());
app.use(express.json());

function firstValid(items) {
  for (let i = 0; i < items.length; i++) {
    const val = items[i];
    if (val !== undefined) {
      if (val !== null) {
        if (val !== '') {
          return val;
        }
      }
    }
  }
  return '';
}

// 1. Initialize Firebase Admin
let db = null;
try {
  let serviceAccount = null;
  const secretPaths = [
    '/etc/secrets/serviceAccountKey.json',
    path.join(__dirname, 'serviceAccountKey.json'),
    path.join(__dirname, '..', 'serviceAccountKey.json'),
  ];

  for (let i = 0; i < secretPaths.length; i++) {
    if (fs.existsSync(secretPaths[i])) {
      serviceAccount = JSON.parse(fs.readFileSync(secretPaths[i], 'utf8'));
      break;
    }
  }

  if (!serviceAccount) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    }
  }

  if (serviceAccount) {
    if (firebaseApp.getApps().length === 0) {
      firebaseApp.initializeApp({
        credential: firebaseApp.cert(serviceAccount),
      });
    }
    db = firebaseFirestore.getFirestore();
    console.log('Firebase Admin initialized successfully.');
  } else {
    console.warn('WARNING: serviceAccountKey.json not found.');
  }
} catch (err) {
  console.error('Firebase Admin init error:', err.message);
}

// 2. Configuration
const APP_ID = firstValid([
  process.env.AGORAApp_ID,
  process.env.AGORA_APP_ID,
  '',
]);

const APP_CERTIFICATE = firstValid([
  process.env.AGORA_APP_CERTIFICATE,
  process.env.AGORAApp_Certificate,
  process.env.AGORA_CERTIFICATE,
  '',
]);

const BINANCE_PAY_ID = firstValid([
  process.env.BINANCE_PAY_ID,
  '1059643208',
]);

const ADMIN_PASSWORD = firstValid([
  process.env.ADMIN_PASSWORD,
  'NileAdmin2026',
]);

const memoryOrders = new Map();

function requireAdmin(req, res, next) {
  const pass = firstValid([
    req.headers['x-admin-password'],
    req.query.password,
    '',
  ]);
  if (pass !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Unauthorized: Invalid Admin Password' });
  }
  next();
}

app.get('/', (req, res) => {
  let hasAgora = false;
  if (APP_ID !== '') {
    if (APP_CERTIFICATE !== '') {
      hasAgora = true;
    }
  }
  res.json({
    status: 'NILE Live Server Running',
    firebaseConnected: Boolean(db),
    agoraConfigured: hasAgora,
    adminDashboard: '/admin',
  });
});

// Serve admin.html from server/ or root folder
app.get('/admin', (req, res) => {
  const candidatePaths = [
    path.join(__dirname, 'admin.html'),
    path.join(__dirname, '..', 'admin.html'),
  ];
  for (let i = 0; i < candidatePaths.length; i++) {
    if (fs.existsSync(candidatePaths[i])) {
      return res.sendFile(candidatePaths[i]);
    }
  }
  return res.status(404).send('admin.html not found.');
});

// 3. Agora RTC Voice Token Endpoints
function generateAgoraToken(req, res) {
  try {
    let body = {};
    if (req.body) {
      body = req.body;
    }
    const channelName = firstValid([
      req.query.channelName,
      req.query.channel,
      req.params.channel,
      body.channelName,
      'habesha_vip_room',
    ]);
    const uidRaw = firstValid([
      req.query.uid,
      req.params.uid,
      body.uid,
      '0',
    ]);
    const uid = parseInt(String(uidRaw), 10);
    const roleRaw = firstValid([
      req.query.role,
      req.params.role,
      body.role,
      'publisher',
    ]);
    const roleStr = String(roleRaw).toLowerCase();

let role = RtcRole.PUBLISHER;
    if (roleStr === 'audience') {
      role = RtcRole.SUBSCRIBER;
    } else if (roleStr === 'subscriber') {
      role = RtcRole.SUBSCRIBER;
    } else if (roleStr === '2') {
      role = RtcRole.SUBSCRIBER;
    }

    if (APP_ID === '') {
      return res.status(500).json({ error: 'Agora APP_ID missing on server' });
    }
    if (APP_CERTIFICATE === '') {
      return res.status(500).json({ error: 'Agora APP_CERTIFICATE missing on server' });
    }

    const expirationTimeInSeconds = 3600 * 24;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpiredTs,
      privilegeExpiredTs
    );

    return res.json({
      token: token,
      rtcToken: token,
      channelName: channelName,
      uid: uid,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
}

app.get(['/token', '/rtcToken', '/getToken', '/rtc/:channel/:role/:tokentype/:uid'], generateAgoraToken);
app.post(['/token', '/rtcToken', '/getToken'], generateAgoraToken);

// 4. User Binance Pay Endpoints
app.post(
  ['/create-order', '/api/create-order', '/binance/create-order', '/api/binance/create-order'],
  async (req, res) => {
    try {
      let body = {};
      if (req.body) {
        body = req.body;
      }
      const resolvedUid = firstValid([body.userUid, body.uid, '']);
      const resolvedNumId = firstValid([body.numericId, body.userNumericId, '100000']);
      const resolvedCoins = parseInt(String(firstValid([body.coins, '0'])), 10);
      const resolvedUsd = parseFloat(String(firstValid([body.usdAmount, body.amount, '0'])));

      const orderRef = 'BNB_' + resolvedNumId + '_' + Date.now();
      const orderData = {
        orderRef: orderRef,
        uid: resolvedUid,
        numericId: String(resolvedNumId),
        coins: resolvedCoins,
        usdAmount: resolvedUsd,
        binancePayId: BINANCE_PAY_ID,
        status: 'PENDING',
        createdAt: new Date().toISOString(),
      };

      memoryOrders.set(orderRef, orderData);

      if (db) {
        await db.collection('binance_orders').doc(orderRef).set({
          orderRef: orderData.orderRef,
          uid: orderData.uid,
          numericId: orderData.numericId,
          coins: orderData.coins,
          usdAmount: orderData.usdAmount,
          binancePayId: orderData.binancePayId,
          status: orderData.status,
          createdAt: orderData.createdAt,
          timestamp: FieldValue.serverTimestamp(),
        });
      }

      return res.json({
        success: true,
        orderRef: orderRef,
        binancePayId: BINANCE_PAY_ID,
        status: 'PENDING',
      });
    } catch (e) {
      return res.status(500).json({ success: false, error: e.message });
    }
  }
);

app.post(
  ['/verify-payment', '/api/verify-payment', '/binance/verify', '/api/binance/verify', '/verify-order', '/api/verify-order'],
  async (req, res) => {
    try {
      let body = {};
      if (req.body) {
        body = req.body;
      }
      const orderRef = firstValid([body.orderRef, '']);
      if (orderRef === '') {
        return res.status(400).json({ success: false, message: 'Order Ref is required.' });
      }

      let order = null;
      if (memoryOrders.has(orderRef)) {
        order = memoryOrders.get(orderRef);
      }

      if (db) {
        const docSnap = await db.collection('binance_orders').doc(orderRef).get();
        if (docSnap.exists) {
          order = docSnap.data();
        }
      }

      if (!order) {
        return res.status(404).json({
          success: false,
          message: 'Order not found. Please contact support with Order Ref.',
        });
      }

      let isPaid = false;
      if (order.status === 'PAID') {
        isPaid = true;
      } else if (order.status === 'APPROVED') {
        isPaid = true;
      }

if (isPaid) {
        return res.json({
          success: true,
          verified: true,
          coinsAdded: order.coins,
          message: 'Payment verified!',
        });
      }

      return res.status(400).json({
        success: false,
        verified: false,
        message: 'Payment not confirmed yet. Please wait 1 minute or contact support with Order Ref.',
      });
    } catch (e) {
      return res.status(500).json({ success: false, message: e.message });
    }
  }
);

// 5. Admin API Endpoints
app.post('/api/admin/login', (req, res) => {
  let body = {};
  if (req.body) {
    body = req.body;
  }
  if (body.password === ADMIN_PASSWORD) {
    return res.json({ success: true });
  }
  return res.status(401).json({ success: false, error: 'Incorrect password' });
});

app.get('/api/admin/overview', requireAdmin, async (req, res) => {
  if (!db) {
    return res.status(500).json({ error: 'Firebase not connected. Check serviceAccountKey.json.' });
  }

  try {
    const results = await Promise.all([
      db.collection('users').limit(200).get(),
      db.collection('binance_orders').limit(100).get(),
      db.collection('coin_recharges').limit(100).get(),
      db.collection('withdraw_requests').limit(100).get(),
      db.collection('agencies').limit(100).get(),
    ]);

    const usersSnap = results[0];
    const bnbSnap = results[1];
    const sellerSnap = results[2];
    const withdrawSnap = results[3];
    const agenciesSnap = results[4];

    let totalRevenueUsd = 0;
    let totalUserCoins = 0;
    let totalUnpaidPoints = 0;

    const users = [];
    usersSnap.forEach((doc) => {
      const d = doc.data();
      totalUserCoins += Number(firstValid([d.coins, 0]));
      totalUnpaidPoints += Number(firstValid([d.points, 0]));
      users.push(Object.assign({ uid: doc.id }, d));
    });

    const userOrders = [];
    bnbSnap.forEach((doc) => {
      const d = doc.data();
      if (d.status === 'PAID') {
        totalRevenueUsd += Number(firstValid([d.usdAmount, 0]));
      } else if (d.status === 'APPROVED') {
        totalRevenueUsd += Number(firstValid([d.usdAmount, 0]));
      }
      userOrders.push(Object.assign({ id: doc.id }, d));
    });

    const sellerOrders = [];
    sellerSnap.forEach((doc) => {
      const d = doc.data();
      if (d.status === 'PAID') {
        totalRevenueUsd += Number(firstValid([d.usdAmount, 0]));
      } else if (d.status === 'APPROVED') {
        totalRevenueUsd += Number(firstValid([d.usdAmount, 0]));
      }
      sellerOrders.push(Object.assign({ id: doc.id }, d));
    });

    const withdrawals = [];
    withdrawSnap.forEach((doc) => {
      withdrawals.push(Object.assign({ id: doc.id }, doc.data()));
    });

    const agencies = [];
    agenciesSnap.forEach((doc) => {
      agencies.push(Object.assign({ id: doc.id }, doc.data()));
    });

    return res.json({
      stats: {
        totalRevenueUsd: totalRevenueUsd,
        totalUserCoins: totalUserCoins,
        totalUnpaidPoints: totalUnpaidPoints,
        totalUsers: users.length,
        totalAgencies: agencies.length,
      },
      userOrders: userOrders,
      sellerOrders: sellerOrders,
      withdrawals: withdrawals,
      users: users,
      agencies: agencies,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.post('/api/admin/user-order', requireAdmin, async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  let body = {};
  if (req.body) {
    body = req.body;
  }
  const orderRef = body.orderRef;
  const action = body.action;

  try {
    const orderRefDoc = db.collection('binance_orders').doc(orderRef);
    const snap = await orderRefDoc.get();
    if (!snap.exists) return res.status(404).json({ error: 'Order not found' });

    const order = snap.data();
    if (order.status !== 'PENDING') {
      return res.status(400).json({ error: 'Order already processed' });
    }

if (action === 'APPROVE') {
      let targetUid = firstValid([order.uid, '']);
      if (targetUid === '') {
        if (order.numericId) {
          const uq = await db.collection('users').where('numericId', '==', Number(order.numericId)).limit(1).get();
          if (!uq.empty) {
            targetUid = uq.docs[0].id;
          }
        }
      }

      const batch = db.batch();
      batch.update(orderRefDoc, {
        status: 'PAID',
        approvedAt: FieldValue.serverTimestamp(),
      });

      if (targetUid !== '') {
        const userDoc = db.collection('users').doc(targetUid);
        batch.set(
          userDoc,
          { coins: FieldValue.increment(Number(firstValid([order.coins, 0]))) },
          { merge: true }
        );
      }

      await batch.commit();
      memoryOrders.set(orderRef, Object.assign({}, order, { status: 'PAID' }));
      return res.json({ success: true, status: 'PAID' });
    } else {
      await orderRefDoc.update({ status: 'REJECTED' });
      memoryOrders.set(orderRef, Object.assign({}, order, { status: 'REJECTED' }));
      return res.json({ success: true, status: 'REJECTED' });
    }
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.post('/api/admin/seller-order', requireAdmin, async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  let body = {};
  if (req.body) {
    body = req.body;
  }
  const orderRef = body.orderRef;
  const action = body.action;

  try {
    const docRef = db.collection('coin_recharges').doc(orderRef);
    const snap = await docRef.get();
    if (!snap.exists) return res.status(404).json({ error: 'Order not found' });

    const order = snap.data();
    if (order.status !== 'PENDING') {
      return res.status(400).json({ error: 'Order already processed' });
    }

    if (action === 'APPROVE') {
      const batch = db.batch();
      batch.update(docRef, {
        status: 'PAID',
        approvedAt: FieldValue.serverTimestamp(),
      });

      if (order.uid) {
        const sellerDoc = db.collection('users').doc(order.uid);
        batch.set(
          sellerDoc,
          { coins: FieldValue.increment(Number(firstValid([order.coins, 0]))) },
          { merge: true }
        );
      }

      await batch.commit();
      return res.json({ success: true, status: 'PAID' });
    } else {
      await docRef.update({ status: 'REJECTED' });
      return res.json({ success: true, status: 'REJECTED' });
    }
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.post('/api/admin/withdrawal', requireAdmin, async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  let body = {};
  if (req.body) {
    body = req.body;
  }
  const requestId = body.requestId;
  const action = body.action;

  try {
    const docRef = db.collection('withdraw_requests').doc(requestId);
    const snap = await docRef.get();
    if (!snap.exists) return res.status(404).json({ error: 'Request not found' });

    const reqData = snap.data();
    if (reqData.status !== 'PENDING') {
      return res.status(400).json({ error: 'Request already processed' });
    }

    if (action === 'PAID') {
      await docRef.update({
        status: 'PAID',
        paidAt: FieldValue.serverTimestamp(),
      });
      return res.json({ success: true, status: 'PAID' });
    } else {
      const batch = db.batch();
      batch.update(docRef, {
        status: 'REJECTED',
        rejectedAt: FieldValue.serverTimestamp(),
      });

      const refundPts = Number(firstValid([reqData.points, 0]));
      let isAgencyComm = false;
      if (reqData.type === 'AGENCY_COMMISSION') {
        if (reqData.agencyId) {
          isAgencyComm = true;
        }
      }

      if (isAgencyComm) {

const agRef = db.collection('agencies').doc(reqData.agencyId);
        batch.update(agRef, {
          withdrawnCommissionPoints: FieldValue.increment(-refundPts),
        });
      } else {
        const targetUid = firstValid([reqData.userUid, reqData.uid, '']);
        if (targetUid !== '') {
          const uRef = db.collection('users').doc(targetUid);
          batch.update(uRef, {
            points: FieldValue.increment(refundPts),
          });
        }
      }

      await batch.commit();
      return res.json({ success: true, status: 'REJECTED' });
    }
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.post('/api/admin/user-control', requireAdmin, async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  let body = {};
  if (req.body) {
    body = req.body;
  }
  const uid = body.uid;

  try {
    const userRef = db.collection('users').doc(uid);
    const snap = await userRef.get();
    if (!snap.exists) return res.status(404).json({ error: 'User not found' });

    const data = snap.data();
    const updates = {};

    if (typeof body.addCoins === 'number') {
      if (body.addCoins !== 0) {
        updates.coins = FieldValue.increment(body.addCoins);
      }
    }
    if (body.toggleFace) {
      updates.isFaceVerified = !data.isFaceVerified;
    }
    if (body.toggleBan) {
      updates.isBanned = !data.isBanned;
    }

    await userRef.update(updates);
    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.post('/api/admin/create-agency', requireAdmin, async (req, res) => {
  if (!db) return res.status(500).json({ error: 'Firebase not connected' });
  let body = {};
  if (req.body) {
    body = req.body;
  }
  const agencyId = firstValid([body.agencyId, '']);
  const agencyName = firstValid([body.agencyName, '']);
  const ownerNumericId = firstValid([body.ownerNumericId, '']);

  try {
    if (agencyId === '') {
      return res.status(400).json({ error: 'Agency ID is required' });
    }
    if (agencyName === '') {
      return res.status(400).json({ error: 'Agency Name is required' });
    }

    let ownerUid = '';
    if (ownerNumericId !== '') {
      const uq = await db.collection('users').where('numericId', '==', Number(ownerNumericId)).limit(1).get();
      if (!uq.empty) {
        ownerUid = uq.docs[0].id;
      }
    }

    await db.collection('agencies').doc(agencyId).set({
      agencyId: agencyId,
      name: agencyName,
      ownerUid: ownerUid,
      ownerNumericId: Number(firstValid([ownerNumericId, 0])),
      commissionRate: 0.15,
      totalHosts: 0,
      withdrawnCommissionPoints: 0,
      bonusCommissionPoints: 0,
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

const PORT = firstValid([process.env.PORT, 3000]);
app.listen(PORT, () => {
  console.log('NILE Live Server running on port ' + PORT);
});
