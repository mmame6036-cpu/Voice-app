const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const UserTask = require('../models/UserTask');
const Transaction = require('../models/Transaction');

const getTodayStr = () => new Date().toISOString().split('T')[0];

// Fetch daily status & recalculate tier rates
router.get('/status/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    let task = await UserTask.findOne({ userId });

    if (!task) {
      task = await UserTask.create({ userId, joinedDate: new Date() });
    }

    const today = getTodayStr();

    if (task.lastActiveDate !== today && task.lastActiveDate !== '') {
      if (task.normalSeatMinutes >= 60) {
        task.consecutiveActiveDays += 1;
        task.consecutiveInactiveDays = 0;
        task.normalSeatRewardRate += 200;
      } else {
        task.consecutiveInactiveDays += 1;
        task.consecutiveActiveDays = 0;
        task.normalSeatRewardRate = Math.max(500, task.normalSeatRewardRate - 250);
      }

      task.normalSeatMinutes = 0;
      task.crownSeatMinutes = 0;
      task.crownGiftCoins = 0;
      task.dailyFollowersCount = 0;
      task.claimedTasks = [];
      task.lastActiveDate = today;
      await task.save();
    } else if (task.lastActiveDate === '') {
      task.lastActiveDate = today;
      await task.save();
    }

    const daysSinceJoined = Math.floor((new Date() - new Date(task.joinedDate)) / (1000 * 60 * 60 * 24));
    const isWithin7Days = daysSinceJoined < 7;

    res.json({
      success: true,
      data: {
        isWithin7Days,
        daysSinceJoined,
        normalSeatMinutes: task.normalSeatMinutes,
        normalSeatRewardRate: task.normalSeatRewardRate,
        crownSeatMinutes: task.crownSeatMinutes,
        crownGiftCoins: task.crownGiftCoins,
        dailyFollowersCount: task.dailyFollowersCount,
        claimedTasks: task.claimedTasks
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Claim task reward
router.post('/claim', async (req, res) => {
  try {
    const { userId, taskId } = req.body;
    let task = await UserTask.findOne({ userId });
    if (!task) return res.status(404).json({ success: false, error: 'Task profile not found' });

    if (task.claimedTasks.includes(taskId)) {
      return res.status(400).json({ success: false, message: 'Task already claimed' });
    }

    let rewardPoints = 0;
    let description = '';

    // 1. 7-Day New User 2hr Seat (8k Points)
    if (taskId === 'new_user_7day') {
      const daysSinceJoined = Math.floor((new Date() - new Date(task.joinedDate)) / (1000 * 60 * 60 * 24));
      if (daysSinceJoined >= 7) {
        return res.status(400).json({ success: false, message: '7-day limit expired' });
      }
      if (task.normalSeatMinutes < 120) {
        return res.status(400).json({ success: false, message: 'Requires 120 minutes on seat' });
      }
      rewardPoints = 8000;
      description = '7-Day New User 2hr Seat Reward';
    }

    // 2. Daily Normal Seat 1hr (Rate from 500 upwards)
    else if (taskId === 'normal_seat_daily') {
      if (task.normalSeatMinutes < 60) {
        return res.status(400).json({ success: false, message: 'Requires 60 minutes on seat' });
      }
      rewardPoints = task.normalSeatRewardRate;
      description = 'Daily Normal Seat Reward (' + rewardPoints + ' pts)';
    }

    // 3. Crown Seat 1hr + 600 Gift Coins
    else if (taskId === 'crown_seat_task') {
      if (task.crownSeatMinutes < 60 || task.crownGiftCoins < 600) {
        return res.status(400).json({ success: false, message: 'Requires 60 mins and 600 gift coins' });
      }
      rewardPoints = 3000;
      description = 'Crown Seat 1hr & 600 Gifts Reward';
    }

    // 4. Gain 3 Followers (1k Points)

else if (taskId === 'followers_task') {
      if (task.dailyFollowersCount < 3) {
        return res.status(400).json({ success: false, message: 'Requires 3 new followers' });
      }
      rewardPoints = 1000;
      description = 'Gain 3 Followers Daily Reward';
    } else {
      return res.status(400).json({ success: false, error: 'Unknown task ID' });
    }

    task.claimedTasks.push(taskId);
    await task.save();

    const User = mongoose.model('User');
    const updatedUser = await User.findOneAndUpdate(
      { userId: String(userId) },
      { $inc: { points: rewardPoints } },
      { new: true }
    );

    await Transaction.create({
      userId: String(userId),
      type: 'task_points_reward',
      amount: rewardPoints,
      balanceAfter: updatedUser ? (updatedUser.points || 0) : 0,
      description: description
    });

    res.json({
      success: true,
      rewardPoints: rewardPoints,
      message: 'Successfully claimed ' + rewardPoints + ' points!'
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Record user activity
router.post('/record-activity', async (req, res) => {
  try {
    const { userId, type, value } = req.body;
    let task = await UserTask.findOne({ userId });
    if (!task) task = await UserTask.create({ userId });

    const val = Number(value) || 1;

    if (type === 'normal_seat') task.normalSeatMinutes += val;
    else if (type === 'crown_
