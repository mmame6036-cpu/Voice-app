const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

const app = express();
app.use(cors());
app.use(express.json());

// 1. Initialize Firebase Admin
let db = null;
try {
  let serviceAccount = null;
  if (fs.existsSync('/etc/secrets/serviceAccountKey.json')) {
    serviceAccount = JSON.parse(fs.readFileSync('/etc/secrets/serviceAccountKey.json', 'utf8'));
  } else if (fs.existsSync('./serviceAccountKey.json')) {
    serviceAccount = JSON.parse(fs.readFileSync('./serviceAccountKey.json', 'utf8'));
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    db = admin.firestore();
    console.log('Firebase Admin initialized successfully.');
  } else {
    console.warn('WARNING: serviceAccountKey.json not found.');
  }
} catch (err) {
  console.error('Firebase Admin init error:', err.message);
}

// 2. Configuration
const APP_ID = process.env.AGORAApp_ID  process.env.AGORA_APP_ID  '';
const APP_CERTIFICATE =
  process.env.AGORA_APP_CERTIFICATE ||
  process.env.AGORAApp_Certificate ||
  process.env.AGORA_CERTIFICATE ||
  '';
const BINANCE_PAY_ID = process.env.BINANCE_PAY_ID || '1059643208';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'NileAdmin2026';

const memoryOrders = new Map();

function requireAdmin(req, res, next) {
  const pass = req.headers['x-admin-password']  req.query.password  '';
  if (pass !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Unauthorized: Invalid Admin Password' });
  }
  next();
}

app.get('/', (req, res) => {
  res.json({
    status: 'NILE Live Server Running',
    firebaseConnected: Boolean(db),
    agoraConfigured: Boolean(APP_ID && APP_CERTIFICATE),
    adminDashboard: '/admin',
  });
});

// Serve standalone admin.html
app.get('/admin', (req, res) => {
  const htmlPath = path.join(__dirname, 'admin.html');
  if (fs.existsSync(htmlPath)) {
    return res.sendFile(htmlPath);
  }
  return res.status(404).send('admin.html not found. Please add admin.html to GitHub repository.');
});

// 3. Agora RTC Voice Token Endpoints
function generateAgoraToken(req, res) {
  try {
    const body = req.body || {};
    const channelName =
      req.query.channelName ||
      req.query.channel ||
      req.params.channel ||
      body.channelName ||
      'habesha_vip_room';
    const uid = parseInt(req.query.uid  req.params.uid  body.uid || '0', 10);
    const roleStr = String(req.query.role  req.params.role  body.role || 'publisher').toLowerCase();
    let role = RtcRole.PUBLISHER;
    if (roleStr === 'audience'  roleStr === 'subscriber'  roleStr === '2') {
      role = RtcRole.SUBSCRIBER;
    }

    if (!APP_ID || !APP_CERTIFICATE) {
      return res.status(500).json({ error: 'Agora credentials missing on server' });
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

    return res.json({ token, rtcToken: token, channelName, uid });
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
      const body = req.body || {};
      const resolvedUid = body.userUid  body.uid  '';
      const resolvedNumId = body.numericId  body.userNumericId  '100000';
      const resolvedCoins = parseInt(body.coins || '0', 10);
      const resolvedUsd = parseFloat(body.usdAmount  body.amount  '0');

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
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
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
      const body = req.body || {};
      const orderRef = body.orderRef;
      if (!orderRef) {
        return res.status(400).json({ success: false, message: 'Order Ref is required.' });
      }

      let order = memoryOrders.get(orderRef) || null;

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

      if (order.status === 'PAID' || order.status === 'APPROVED') {
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
  const body = req.body || {};
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
      totalUserCoins += Number(d.coins || 0);
      totalUnpaidPoints += Number(d.points || 0);
      users.push(Object.assign({ uid: doc.id }, d));
    });

    const userOrders = [];
    bnbSnap.forEach((doc) => {
      const d = doc.data();
      if (d.status === 'PAID' || d.status === 'APPROVED') {
        totalRevenueUsd += Number(d.usdAmount || 0);
      }
      userOrders.push(Object.assign({ id: doc.id }, d));
    });

    const sellerOrders = [];
    sellerSnap.forEach((doc) => {
      const d = doc.data();
      if (d.status === 'PAID' || d.status === 'APPROVED') {
        totalRevenueUsd += Number(d.usdAmount || 0);
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
  const body = req.body || {};
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
      let targetUid = order.uid;
      if (!targetUid && order.numericId) {
        const uq = await db.collection('users').where('numericId', '==', Number(order.numericId)).limit(1).get();
        if (!uq.empty) targetUid = uq.docs[0].id;
      }

      const batch = db.batch();
      batch.update(orderRefDoc, {
        status: 'PAID',
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (targetUid) {
        const userDoc = db.collection('users').doc(targetUid);
        batch.set(
          userDoc,
          { coins: admin.firestore.FieldValue.increment(Number(order.coins || 0)) },
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
  const body = req.body || {};
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
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

if (order.uid) {
        const sellerDoc = db.collection('users').doc(order.uid);
        batch.set(
          sellerDoc,
          { coins: admin.firestore.FieldValue.increment(Number(order.coins || 0)) },
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
  const body = req.body || {};
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
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return res.json({ success: true, status: 'PAID' });
    } else {
      const batch = db.batch();
      batch.update(docRef, {
        status: 'REJECTED',
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const refundPts = Number(reqData.points || 0);
      if (reqData.type === 'AGENCY_COMMISSION' && reqData.agencyId) {
        const agRef = db.collection('agencies').doc(reqData.agencyId);
        batch.update(agRef, {
          withdrawnCommissionPoints: admin.firestore.FieldValue.increment(-refundPts),
        });
      } else if (reqData.userUid || reqData.uid) {
        const targetUid = reqData.userUid || reqData.uid;
        const uRef = db.collection('users').doc(targetUid);
        batch.update(uRef, {
          points: admin.firestore.FieldValue.increment(refundPts),
        });
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
  const body = req.body || {};
  const uid = body.uid;

  try {
    const userRef = db.collection('users').doc(uid);
    const snap = await userRef.get();
    if (!snap.exists) return res.status(404).json({ error: 'User not found' });

    const data = snap.data();
    const updates = {};

    if (typeof body.addCoins === 'number' && body.addCoins !== 0) {
      updates.coins = admin.firestore.FieldValue.increment(body.addCoins);
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
  const body = req.body || {};
  const agencyId = body.agencyId;
  const agencyName = body.agencyName;
  const ownerNumericId = body.ownerNumericId;

  try {
    if (!agencyId || !agencyName) {
      return res.status(400).json({ error: 'Agency ID and Name are required' });
    }

    let ownerUid = '';
    if (ownerNumericId) {
      const uq = await db.collection('users').where('numericId', '==', Number(ownerNumericId)).limit(1).get();
      if (!uq.empty) {
        ownerUid = uq.docs[0].id;
      }
    }

await db.collection('agencies').doc(agencyId).set({
      agencyId: agencyId,
      name: agencyName,
      ownerUid: ownerUid,
      ownerNumericId: Number(ownerNumericId || 0),
      commissionRate: 0.15,
      totalHosts: 0,
      withdrawnCommissionPoints: 0,
      bonusCommissionPoints: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('NILE Live Server running on port ' + PORT);
});
