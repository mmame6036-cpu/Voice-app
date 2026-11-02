const express = require('express');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Firebase Admin Initialization
const secretPath = fs.existsSync('/etc/secrets/serviceAccountKey.json')
  ? '/etc/secrets/serviceAccountKey.json'
  : path.join(__dirname, 'serviceAccountKey.json');

try {
  const serviceAccount = require(secretPath);
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  }
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Firebase Admin init error:', error.message);
}

// Agora Credentials
const APP_ID = 'd00a25d96dfc44cc866cd8f41c496b36';
const APP_CERTIFICATE = 'f612162b922c4dc4857cf5ab274c0108';

// Firebase Custom Token Endpoint
app.post('/auth/custom-token', async (req, res) => {
  const { identifier } = req.body;

  if (!identifier) {
    return res.status(400).json({ error: 'identifier is required' });
  }

  // Backtick ስህተት እንዳይፈጥር በተራ + ተቀናጅቷል
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

// Agora RTC Token Endpoint
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
