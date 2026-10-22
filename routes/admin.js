const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// 1. Freeze / Block Account
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

    const actionText = isFrozen ? 'frozen' : 'unfrozen';

    return res.json({
      success: true,
      message: 'User account has been ' + actionText + ' successfully',
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

// 2. Fraud Detection Log
router.get('/suspicious-activity', async (req, res) => {
  try {
    const Transaction = mongoose.model('Transaction');
    
    // Identify users with more than 15 transactions in the last 10 minutes
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

    const suspiciousUsers = await Transaction.aggregate([
      { $match: { createdAt: { $gte: tenMinutesAgo } } },
      { $group: { _id: "$userId", count: { $sum: 1 }, totalAmount: { $sum: "$amount" } } },
      { $match: { count: { $gt: 15 } } },
      { $sort: { count: -1 } }
    ]);

    return res.json({ success: true, count: suspiciousUsers.length, suspiciousUsers });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
