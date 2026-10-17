const express = require('express');
const router = express.Router();
const UserTask = require('../models/UserTask');
const mongoose = require('mongoose');

const getTodayString = () => {
  const now = new Date();
  return now.toISOString().split('T')[0];
};

// 1. Get Today Tasks Progress
router.get('/today', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }

    const today = getTodayString();
    let taskDoc = await UserTask.findOne({ userId: String(userId), date: today });

    if (!taskDoc) {
      taskDoc = new UserTask({
        userId: String(userId),
        date: today,
        checkInDay: 1
      });
      await taskDoc.save();
    }

    return res.json({
      success: true,
      tasks: taskDoc
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 2. Daily Check-in API
router.post('/check-in', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }

    const today = getTodayString();
    let taskDoc = await UserTask.findOne({ userId: String(userId), date: today });

    if (!taskDoc) {
      taskDoc = new UserTask({ userId: String(userId), date: today });
    }

    if (taskDoc.isCheckedIn) {
      return res.status(400).json({ success: false, message: 'Already checked in today' });
    }

    const dayRewardMap = {
      1: 20,
      2: 30,
      3: 40,
      4: 50,
      5: 60,
      6: 80,
      7: 100
    };

    const currentDay = taskDoc.checkInDay ? taskDoc.checkInDay : 1;
    const coinsReward = dayRewardMap[currentDay] ? dayRewardMap[currentDay] : 20;

    taskDoc.isCheckedIn = true;
    await taskDoc.save();

    const User = mongoose.models.User;
    let newBalance = 0;
    if (User) {
      const updatedUser = await User.findOneAndUpdate(
        { userId: String(userId) },
        { $inc: { coins: coinsReward } },
        { new: true }
      );
      if (updatedUser) newBalance = updatedUser.coins;
    }

    return res.json({
      success: true,
      message: 'Check-in successful',
      rewardCoins: coinsReward,
      currentDay: currentDay,
      newBalance: newBalance
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 3. Claim Task Reward API
router.post('/claim', async (req, res) => {
  try {
    const { userId, taskType } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }
    if (!taskType) {
      return res.status(400).json({ success: false, message: 'Task type is required' });
    }

    const today = getTodayString();
    const taskDoc = await UserTask.findOne({ userId: String(userId), date: today });
    if (!taskDoc) {
      return res.status(404).json({ success: false, message: 'Task record not found' });
    }

    let rewardCoins = 0;

    if (taskType === 'stay10') {
      if (taskDoc.stay10Claimed) return res.status(400).json({ success: false, message: 'Already claimed' });
      if (taskDoc.stayDurationMinutes < 10) return res.status(400).json({ success: false, message: 'Task not completed' });
      taskDoc.stay10Claimed = true;
      rewardCoins = 30;
    } else if (taskType === 'stay30') {
      if (taskDoc.stay30Claimed) return res.status(400).json({ success: false, message: 'Already claimed' });
      if (taskDoc.stayDurationMinutes < 30) return res.status(400).json({ success: false, message: 'Task not completed' });
      taskDoc.stay30Claimed = true;
      rewardCoins = 60;
    } else if (taskType === 'gift') {
      if (taskDoc.giftClaimed) return res.status(400).json({ success: false, message: 'Already claimed' });

if (taskDoc.giftSentCount < 1) return res.status(400).json({ success: false, message: 'Task not completed' });
      taskDoc.giftClaimed = true;
      rewardCoins = 50;
    } else if (taskType === 'messages') {
      if (taskDoc.messageClaimed) return res.status(400).json({ success: false, message: 'Already claimed' });
      if (taskDoc.messagesSentCount < 5) return res.status(400).json({ success: false, message: 'Task not completed' });
      taskDoc.messageClaimed = true;
      rewardCoins = 20;
    } else if (taskType === 'share') {
      if (taskDoc.shareClaimed) return res.status(400).json({ success: false, message: 'Already claimed' });
      if (!taskDoc.shareDone) return res.status(400).json({ success: false, message: 'Task not completed' });
      taskDoc.shareClaimed = true;
      rewardCoins = 25;
    } else {
      return res.status(400).json({ success: false, message: 'Invalid task type' });
    }

    await taskDoc.save();

    const User = mongoose.models.User;
    let newBalance = 0;
    if (User) {
      const updatedUser = await User.findOneAndUpdate(
        { userId: String(userId) },
        { $inc: { coins: rewardCoins } },
        { new: true }
      );
      if (updatedUser) newBalance = updatedUser.coins;
    }

    return res.json({
      success: true,
      message: 'Reward claimed successfully',
      rewardCoins: rewardCoins,
      newBalance: newBalance
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
