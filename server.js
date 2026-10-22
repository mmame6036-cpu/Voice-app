const express = require('express');
const http = require('http');
const cors = require('cors');
const mongoose = require('mongoose');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();
const server = http.createServer(app);

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Core Routes
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const agencyRoutes = require('./routes/agency');
const taskRoutes = require('./routes/tasks');

app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/agency', agencyRoutes);
app.use('/api/tasks', taskRoutes);

// User Registration Endpoint
app.post('/api/register-user', (req, res) => {
  try {
    const { userId, userName, avatar, invitedBy } = req.body;
    console.log('User registration attempt:', { userId, userName, invitedBy });

    return res.status(200).json({
      success: true,
      message: 'User registered successfully',
      user: {
        userId: userId || 'user_' + Date.now(),
        userName: userName || 'New User',
        avatar: avatar || '',
        coins: 1000,
        points: 0
      }
    });
  } catch (error) {
    console.error('Register API Error:', error);
    return res.status(500).json({ success: false, message: 'Server internal error' });
  }
});

// Agora Token Generation Endpoint
const AGORA_APP_ID = process.env.AGORA_APP_ID || '1523b6d3b8144281a1a21f28bbbd7fef';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

app.get('/api/agora/token', (req, res) => {
  try {
    const channelName = req.query.channelName;
    const uid = req.query.uid ? Number(req.query.uid) : 0;
    const isHost = req.query.isHost === 'true';
    const role = isHost ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    if (!channelName) {
      return res.status(400).json({ error: 'channelName is required' });
    }

    if (!AGORA_APP_CERTIFICATE) {
      console.error('AGORA_APP_CERTIFICATE is missing');
      return res.status(500).json({ error: 'AGORA_APP_CERTIFICATE is not configured' });
    }

    // ቶከኑ ለ 24 ሰዓት ያገለግላል
    const expirationTimeInSeconds = 3600 * 24;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpiredTs
    );

    console.log('Agora token generated for channel:', channelName);
    return res.status(200).json({ token });
  } catch (error) {
    console.error('Agora Token Generation Error:', error);
    return res.status(500).json({ error: 'Failed to generate token' });
  }
});

// Root Endpoint
app.get('/', (req, res) => {
  res.send('Nile Voice App Server is Running Successfully!');
});

// Port & MongoDB Connection
const PORT = process.env.PORT || 10000;
const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;

if (MONGO_URI) {
  mongoose.connect(MONGO_URI)
    .then(() => console.log('MongoDB Connected Successfully'))
    .catch((err) => console.error('MongoDB Connection Error:', err));
} else {
  console.log('Running without MONGO_URI string');
}

server.listen(PORT, () => {
  console.log('Server is running on port ' + PORT);
});
