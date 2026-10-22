const express = require('express');
const http = require('http');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
const server = http.createServer(app);

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Core Routes (ያስተካከልናቸው ንጹሕ ፋይሎች)
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const agencyRoutes = require('./routes/agency');
const taskRoutes = require('./routes/tasks');

app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/agency', agencyRoutes);
app.use('/api/tasks', taskRoutes);

// User Registration Endpoint (ስህተቱን የሚፈታው አዲሱ መስመር)
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
