const mongoose = require('mongoose');

const userTaskSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  joinedDate: { type: Date, default: Date.now },
  lastActiveDate: { type: String, default: '' },
  
  normalSeatMinutes: { type: Number, default: 0 },
  normalSeatRewardRate: { type: Number, default: 1000 },
  consecutiveActiveDays: { type: Number, default: 0 },
  consecutiveInactiveDays: { type: Number, default: 0 },

  crownSeatMinutes: { type: Number, default: 0 },
  crownGiftCoins: { type: Number, default: 0 },

  dailyFollowersCount: { type: Number, default: 0 },
  coinsSent: { type: Number, default: 0 },
  gameBetting: { type: Number, default: 0 },

  claimedTasks: { type: [String], default: [] }
}, { timestamps: true });

module.exports = mongoose.models.UserTask || mongoose.model('UserTask', userTaskSchema);

const mongoose = require('mongoose');

const userTaskSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  joinedDate: { type: Date, default: Date.now },
  lastActiveDate: { type: String, default: '' },
  
  normalSeatMinutes: { type: Number, default: 0 },
  normalSeatRewardRate: { type: Number, default: 1000 },
  consecutiveActiveDays: { type: Number, default: 0 },
  consecutiveInactiveDays: { type: Number, default: 0 },

  crownSeatMinutes: { type: Number, default: 0 },
  crownGiftCoins: { type: Number, default: 0 },

  dailyFollowersCount: { type: Number, default: 0 },
  coinsSent: { type: Number, default: 0 },
  gameBetting: { type: Number, default: 0 },

  claimedTasks: { type: [String], default: [] }
}, { timestamps: true });

module.exports = mongoose.models.UserTask || mongoose.model('UserTask', userTaskSchema);
