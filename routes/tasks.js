const express = require('express');
const router = express.Router();
const UserTask = require('../models/UserTask');

const getTodayDate = () => new Date().toISOString().split('T')[0];

// Helper: Check if user registered within last 7 days
const checkWithin7Days = (joinedDate) => {
  if (!joinedDate) return false;
  const diffTime = Math.abs(new Date() - new Date(joinedDate));
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays <= 7;
};

// 1. Fetch Task Status for UI (/api/tasks/status/:userId)
router.get('/status/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const today = getTodayDate();

    let taskData = await UserTask.findOne({ userId });

    if (!taskData) {
      taskData = new UserTask({
        userId,
        lastActiveDate: today,
        consecutiveActiveDays: 1,
      });
      await taskData.save();
    } else if (taskData.lastActiveDate !== today) {
      taskData.normalSeatMinutes = 0;
      taskData.crownSeatMinutes = 0;
      taskData.crownGiftCoins = 0;
      taskData.dailyFollowersCount = 0;
      taskData.coinsSent = 0;
      taskData.gameBetting = 0;
      taskData.claimedTasks = [];
      taskData.lastActiveDate = today;
      await taskData.save();
    }

    const isWithin7Days = checkWithin7Days(taskData.joinedDate);

    return res.status(200).json({
      success: true,
      data: {
        isWithin7Days,
        normalSeatMinutes: taskData.normalSeatMinutes,
        normalSeatRewardRate: taskData.normalSeatRewardRate,
        crownSeatMinutes: taskData.crownSeatMinutes,
        crownGiftCoins: taskData.crownGiftCoins,
        dailyFollowersCount: taskData.dailyFollowersCount,
        coinsSent: taskData.coinsSent,
        gameBetting: taskData.gameBetting,
        claimedTasks: taskData.claimedTasks,
      },
    });
  } catch (error) {
    console.error('Error fetching task status:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// 2. Claim Specific Task Reward
router.post('/claim', async (req, res) => {
  try {
    const { userId, taskId } = req.body;

    if (!userId || !taskId) {
      return res.status(400).json({ success: false, message: 'Missing userId or taskId' });
    }

    const taskData = await UserTask.findOne({ userId });
    if (!taskData) {
      return res.status(404).json({ success: false, message: 'User task profile not found' });
    }

    if (taskData.claimedTasks.includes(taskId)) {
      return res.status(400).json({ success: false, message: 'Task already claimed today' });
    }

    // Task Validation Logic
    let isEligible = false;
    let rewardPoints = 0;
    let rewardCoins = 0;

    switch (taskId) {
      case 'new_user_7day':
        if (checkWithin7Days(taskData.joinedDate) && taskData.normalSeatMinutes >= 120) {
          isEligible = true;
          rewardPoints = 8000;
        }
        break;

      case 'normal_seat_daily':
        if (taskData.normalSeatMinutes >= 60) {
          isEligible = true;
          rewardPoints = taskData.normalSeatRewardRate || 1000;
        }
        break;

      case 'crown_seat_task':
        if (taskData.crownSeatMinutes >= 60 && taskData.crownGiftCoins >= 600) {
          isEligible = true;
          rewardPoints = 3000;
        }
        break;

      case 'crown_room_reward':
        if (taskData.crownSeatMinutes >= 60) {
          isEligible = true;
          rewardPoints = 5000;
        }
        break;

      case 'followers_task':
        if (taskData.dailyFollowersCount >= 3) {
          isEligible = true;
          rewardPoints = 1000;
        }
        break;

      case 'stay_10_coins':
        if (taskData.normalSeatMinutes >= 10) {
          isEligible = true;
          rewardCoins = 1000;
        }
        break;

      case 'gift_flow_100k':
        if (taskData.coinsSent >= 100000) {
          isEligible = true;
          rewardCoins = 1000;
        }
        break;

case 'game_flow_100k':
        if (taskData.gameBetting >= 100000) {
          isEligible = true;
          rewardCoins = 1000;
        }
        break;

      default:
        return res.status(400).json({ success: false, message: 'Unknown task ID' });
    }

    if (!isEligible) {
      return res.status(400).json({ success: false, message: 'Task requirements not satisfied yet' });
    }

    taskData.claimedTasks.push(taskId);
    await taskData.save();

    return res.status(200).json({
      success: true,
      message: 'Claim successful!',
      rewardPoints,
      rewardCoins,
      claimedTasks: taskData.claimedTasks,
    });
  } catch (error) {
    console.error('Error claiming task:', error);
    return res.status(500).json({ success: false, message: 'Server error during claim' });
  }
});

// 3. Progress Updater (Called when user sits, sends gifts, or bets)
router.post('/update-progress', async (req, res) => {
  try {
    const { userId, type, value } = req.body;
    const today = getTodayDate();

    let taskData = await UserTask.findOne({ userId });
    if (!taskData) {
      taskData = new UserTask({ userId, lastActiveDate: today });
    }

    const val = Number(value) || 0;

    if (type === 'normal_seat') taskData.normalSeatMinutes += val;
    if (type === 'crown_seat') taskData.crownSeatMinutes += val;
    if (type === 'crown_gift') taskData.crownGiftCoins += val;
    if (type === 'follower') taskData.dailyFollowersCount += val;
    if (type === 'coins_sent') taskData.coinsSent += val;
    if (type === 'game_betting') taskData.gameBetting += val;

    taskData.lastActiveDate = today;
    await taskData.save();

    return res.status(200).json({ success: true, data: taskData });
  } catch (error) {
    console.error('Error updating progress:', error);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
