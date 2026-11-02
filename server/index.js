const express = require('express');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// --- FIREBASE ADMIN INITIALIZATION ---
let serviceAccount = null;
const possiblePaths = [
  '/etc/secrets/serviceAccountKey.json',
  path.join(__dirname, 'serviceAccountKey.json'),
  path.join(__dirname, '../serviceAccountKey.json')
];

for (const p of possiblePaths) {
  if (fs.existsSync(p)) {
    try {
      const fileData = fs.readFileSync(p, 'utf8');
      serviceAccount = JSON.parse(fileData);
      console.log('Found and loaded serviceAccountKey at:', p);
      break;
    } catch (err) {
      console.error('Error parsing JSON from', p, err.message);
    }
  }
}

if (serviceAccount) {
  try {
    if (!admin.apps || admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    }
    console.log('Firebase Admin initialized successfully!');
  } catch (err) {
    console.error('Firebase Admin init error:', err.message);
  }
} else {
  console.error('serviceAccountKey.json could not be found in known paths');
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
    const customToken = await admin.auth().createCustomToken(sanitizedUid);
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
  res.send('Server is running smoothly');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
