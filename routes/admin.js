const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// 1. የተጠቃሚን አካውንት ማገድ ወይም ማሰር (Freeze/Block Account)
router.post('/freeze-user', async (req, res) => {
  try {
    const { userId, isFrozen, reason } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, error: 'User ID is required' });
    }

    const User = mongoose.model('User');
    const user = await User.findOneAndUpdate(
      { userId: String(userId) },
      { isFrozen: Boolean(isFrozen) },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    return res.json({
      success: true,
      message: 'user account has been ' + (isFrozen ? 'frozen' : ' successfully',
      user: {
        userId: user.userId,
        isFrozen: user.isFrozen,
        reason: reason || 'Suspicious activity detected'
      }
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// 2. ተጠርጣሪ እንቅስቃሴዎችን መፈተሻ (Fraud Detection Log)
router.get('/suspicious-activity', async (req, res) => {
  try {
    const Transaction = mongoose.model('Transaction');
    
    // ባለፉት 10 ደቂቃዎች ውስጥ ከ15 በላይ ግብይት የፈጸሙ ተጠቃሚዎችን መለየት
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

    const suspiciousUsers = await Transaction.aggregate([
      { $match: { createdAt: {$gte: tenMinutesAgo } } },
      { $group: { _id: "$userId", count: { $sum: 1 }, totalAmount: { $sum: "$amount" } } },
      { $match: { count: { $gt: 15 } } },       {$sort: { count: -1 } }
    ]);

    return res.json({ success: true, count: suspiciousUsers.length, suspiciousUsers });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
