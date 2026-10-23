const mongoose = require('mongoose');

const userTaskSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  joinedDate: { type: Date, default: Date.now },
  lastActiveDate: { type: String, default: '' },
  
  // Normal Seat
  normalSeatMinutes: { type: Number, default: 0 },
  normalSeatRewardRate: { type: Number, default: 1000 },
  consecutiveActiveDays: { type: Number, default: 0 },
  consecutiveInactiveDays: { type: Number, default: 0 },

  // Crown / Golden Seat
  crownSeatMinutes: { type: Number, default: 0 },
  crownGiftCoins: { type: Number, default: 0 },

  // Followers & Flow
  dailyFollowersCount: { type: Number, default: 0 },
  coinsSent: { type: Number, default: 0 },
  gameBetting: { type: Number, default: 0 },

  // Claimed Task IDs
  claimedTasks: { type: [String], default: [] }
}, { timestamps: true });

module.exports = mongoose.models.UserTask || mongoose.model('UserTask', userTaskSchema);
