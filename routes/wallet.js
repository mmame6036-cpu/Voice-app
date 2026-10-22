const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const verifyToken = require('../middleware/auth');

// Apply JWT authentication to all wallet endpoints
router.use(verifyToken);

// 1. Bet Endpoint (Protected & Atomic)
router.post('/bet', async (req, res) => {
  try {
    const { betAmount, gameName } = req.body;
    const userId = req.user.userId;
    const amount = Number(betAmount);

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid bet parameters' });
    }

    const User = mongoose.model('User');

    // Check account status and deduct balance atomically
    const user = await User.findOneAndUpdate(
      { userId: String(userId), isFrozen: { $ne: true }, coins: { $gte: amount } },
      { $inc: { coins: -amount } },
      { new: true }
    );

    if (!user) {
      return res.status(400).json({ 
        success: false, 
        error: 'Insufficient coins balance, account frozen, or user not found' 
      });
    }

    // Ledger record
    await Transaction.create({
      userId: String(userId),
      type: 'game_bet',
      amount: -amount,
      balanceAfter: user.coins,
      description: (gameName || 'Game') + ' Bet'
    });

    const io = req.app.get('io');
    if (io) {
      io.to(String(userId)).emit('wallet_updated', { coins: user.coins });
    }

    return res.json({
      success: true,
      message: 'Bet deducted securely',
      remainingCoins: user.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Win Endpoint (Protected)
router.post('/win', async (req, res) => {
  try {
    const { winAmount, gameName } = req.body;
    const userId = req.user.userId;
    const amount = Number(winAmount);

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid win amount' });
    }

    const User = mongoose.model('User');

    const user = await User.findOneAndUpdate(
      { userId: String(userId), isFrozen: { $ne: true } },
      { $inc: { coins: amount } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found or account is frozen' });
    }

    await Transaction.create({
      userId: String(userId),
      type: 'game_win',
      amount: amount,
      balanceAfter: user.coins,
      description: (gameName || 'Game') + ' Win Reward'
    });

    const io = req.app.get('io');
    if (io) {
      io.to(String(userId)).emit('wallet_updated', { coins: user.coins });
    }

    return res.json({
      success: true,
      message: 'Win credited securely',
      newBalance: user.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 3. Auto-refund Endpoint (Protected & Atomic)
router.post('/refund', async (req, res) => {
  try {
    const { refundAmount, reason } = req.body;
    const userId = req.user.userId;
    const amount = Number(refundAmount);

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid refund parameters' });
    }

    const User = mongoose.model('User');

    const user = await User.findOneAndUpdate(
      { userId: String(userId) },
      { $inc: { coins: amount } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    await Transaction.create({
      userId: String(userId),
      type: 'recharge',
      amount: amount,
      balanceAfter: user.coins,
      description: 'Refund: ' + (reason || 'Network/Game Error')
    });

    const io = req.app.get('io');
    if (io) {
      io.to(String(userId)).emit('wallet_updated', { coins: user.coins });
    }

return res.json({
      success: true,
      message: 'Coins refunded successfully',
      newBalance: user.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 4. Ledger History Endpoint (Protected)
router.get('/history', async (req, res) => {
  try {
    const userId = req.user.userId;

    const history = await Transaction.find({ userId: String(userId) })
      .sort({ createdAt: -1 })
      .limit(50);

    return res.json({ success: true, history });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
