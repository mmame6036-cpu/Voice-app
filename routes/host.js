const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// 1. Host Stats Schema
const hostStatsSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true, index: true },
  totalIncome: { type: Number, default: 0 },
  consume: { type: Number, default: 0 },
  gifts: { type: Number, default: 0 },
  baseSalary: { type: Number, default: 0 },
  tasks: { type: Number, default: 0 },
  other: { type: Number, default: 0 },
  liveDurationMinutes: { type: Number, default: 0 },
  agentName: { type: String, default: 'No agent' },
  hourlyIncome: { type: Number, default: 0 },
  lastActiveDate: { type: String, default: '' }
}, { timestamps: true });

const HostStats = mongoose.models.HostStats || mongoose.model('HostStats', hostStatsSchema);

// 2. GET Host Center Data Endpoint
router.get('/center/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    let stats = await HostStats.findOne({ userId });

    if (!stats) {
      stats = new HostStats({
        userId,
        lastActiveDate: new Date().toISOString().split('T')[0]
      });
      await stats.save();
    }

    return res.status(200).json({
      success: true,
      data: {
        userId: stats.userId,
        totalIncome: stats.totalIncome,
        consume: stats.consume,
        gifts: stats.gifts,
        baseSalary: stats.baseSalary,
        tasks: stats.tasks,
        other: stats.other,
        liveDurationMinutes: stats.liveDurationMinutes,
        agentName: stats.agentName,
        hourlyIncome: stats.hourlyIncome
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Server error fetching host data' });
  }
});

// 3. POST Update Live Duration & Income Endpoint
router.post('/record-session', async (req, res) => {
  try {
    const { userId, durationMinutes, giftPoints } = req.body;
    let stats = await HostStats.findOne({ userId });

    if (!stats) {
      stats = new HostStats({ userId });
    }

    const mins = Number(durationMinutes) || 0;
    const gifts = Number(giftPoints) || 0;

    stats.liveDurationMinutes += mins;
    stats.gifts += gifts;
    stats.totalIncome += gifts;

    await stats.save();

    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Error updating host session' });
  }
});

module.exports = router;
