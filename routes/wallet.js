const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');

// 1. Bet Endpoint (ነጥብ 1 እና ነጥብ 4 - Atomic Deduction)
router.post('/bet', async (req, res) => {
  try {
    const { userId, betAmount, gameName } = req.body;
    const amount = Number(betAmount);

    if (!userId  isNaN(amount)  amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid bet parameters' });
    }

    const User = mongoose.model('User');

    // Atomic Operation ($inc) - በተመሳሳይ ሰከንድ ሁለት ጊዜ እንዳይቆረጥ ያደርጋል
    const user = await User.findOneAndUpdate(
      { userId: String(userId), coins: { $gte: amount } },
      { $inc: { coins: -amount } },
      { new: true }
    );

    if (!user) {
      return res.status(400).json({ 
        success: false, 
        error: 'Insufficient coins balance or user not found' 
      });
    }

    // Ledger Record (ነጥብ 2)
    await Transaction.create({
      userId: String(userId),
      type: 'game_bet',
      amount: -amount,
      balanceAfter: user.coins,
      description: ${gameName || 'Game'} Bet
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

// 2. Win Endpoint
router.post('/win', async (req, res) => {
  try {
    const { userId, winAmount, gameName } = req.body;
    const amount = Number(winAmount);

    if (!userId  isNaN(amount)  amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid win amount' });
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
      type: 'game_win',
      amount: amount,
      balanceAfter: user.coins,
      description: ${gameName || 'Game'} Win Reward
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

// 3. Auto-refund Endpoint (ነጥብ 4 - ኔትወርክ ሲቋረጥ ወይም ጨዋታ ሳይጀመር ሲቀር ሳንቲም መመለሻ)
router.post('/refund', async (req, res) => {
  try {
    const { userId, refundAmount, reason } = req.body;
    const amount = Number(refundAmount);

    if (!userId  isNaN(amount)  amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid refund parameters' });
    }

    const User = mongoose.model('User');

    // ሳንቲሙን በ Atomic ኦፕሬሽን ወዲያውኑ መመለስ
    const user = await User.findOneAndUpdate(
      { userId: String(userId) },
      { $inc: { coins: amount } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // በታሪክ መዝገብ ላይ ማስፈር
    await Transaction.create({
      userId: String(userId),
      type: 'recharge',
      amount: amount,
      balanceAfter: user.coins,
      description: Refund: ${reason || 'Network/Game Error'}
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

// 4. Ledger History Endpoint
router.get('/history', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ success: false, error: 'User ID is required' });
    }

    const history = await Transaction.find({ userId: String(userId) })
      .sort({ createdAt: -1 })
      .limit(50);

    return res.json({ success: true, history });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
