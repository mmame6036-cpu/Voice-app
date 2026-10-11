const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');

// 1. የውርርድ ሳንቲም በሰርቨር ብቻ መቁረጥና ታሪክ መመዝገብ (Bet Endpoint)
router.post('/bet', async (req, res) => {
  try {
    const { userId, betAmount, gameName } = req.body;
    const amount = Number(betAmount);

    if (!userId  isNaN(amount)  amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid bet parameters' });
    }

    const User = mongoose.model('User');

    // ሳንቲም በቂ መሆኑን አረጋግጦ መቁረጥ (Backend Authority)
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

    // የግብይት ታሪክ መዝግቦ መያዝ (Transaction Ledger)
    await Transaction.create({
      userId: String(userId),
      type: 'game_bet',
      amount: -amount,
      balanceAfter: user.coins,
      description: ${gameName || 'Game'} Bet
    });

    // Socket.io ካለ አዲሱን ቀሪ ሂሳብ ማሳወቅ
    const io = req.app.get('io');
    if (io) {
      io.to(String(userId)).emit('wallet_updated', { coins: user.coins });
    }

    return res.json({
      success: true,
      message: 'Bet deducted and logged securely',
      remainingCoins: user.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 2. የማሸነፊያ ሳንቲም መጨመርና ታሪክ መመዝገብ (Win Endpoint)
router.post('/win', async (req, res) => {
  try {
    const { userId, winAmount, gameName } = req.body;
    const amount = Number(winAmount);

    if (!userId  isNaN(amount)  amount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid win amount' });
    }

    const User = mongoose.model('User');

    // ያሸነፈውን ሳንቲም በዳታቤዝ መጨመር
    const user = await User.findOneAndUpdate(
      { userId: String(userId) },
      { $inc: { coins: amount } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // የግብይት ታሪክ መዝገብ
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
      message: 'Win credited and logged securely',
      newBalance: user.coins
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 3. የግብይት ታሪክ ማምጫ API (Fetch Ledger History)
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
