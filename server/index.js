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
// Render secret files are mounted at /etc/secrets/ or current directory
const secretPath = fs.existsSync('/etc/secrets/serviceAccountKey.json')
  ? '/etc/secrets/serviceAccountKey.json'
  : path.join(__dirname, 'serviceAccountKey.json');

try {
  const serviceAccount = require(secretPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin initialized successfully using:', secretPath);
} catch (error) {
  console.error('Firebase Admin initialization error:', error.message);
}

// --- AGORA CREDENTIALS ---
const APP_ID = 'd00a25d96dfc44cc866cd8f41c496b36';
const APP_CERTIFICATE = 'f612162b922c4dc4857cf5ab274c0108';

// --- FIREBASE CUSTOM AUTH ENDPOINT ---
app.post('/auth/custom-token', async (req, res) => {
  const { identifier } = req.body;

  if (!identifier) {
    return res.status(400).json({ error: 'identifier is required' });
  }

  // Generate clean alphanumeric UID (e.g., user_251912345678)
  const sanitizedUid = user_${identifier.toString().replace(/[^a-zA-Z0-9_]/g, '_')};

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
  res.send('Agora and Auth Server is running smoothly');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
