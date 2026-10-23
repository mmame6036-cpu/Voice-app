const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Core Routes
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const agencyRoutes = require('./routes/agency');
const taskRoutes = require('./routes/tasks');
const hostRoutes = require('./routes/host');

app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/agency', agencyRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/host', hostRoutes);

app.get('/', (req, res) => {
  res.send('Server is running smoothly');
});

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('Database Connected Successfully');
    app.listen(PORT, () => console.log(Server running on port ${PORT}));
  })
  .catch((err) => {
    console.error('Database connection error:', err);
  });
