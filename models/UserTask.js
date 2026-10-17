const mongoose = require('mongoose');

const userTaskSchema = new mongoose.Schema({
  userId: { 
    type: String, 
    required: true 
  },
  date: { 
    type: String, 
    required: true 
  },
  isCheckedIn: { 
    type: Boolean, 
    default: false 
  },
  checkInDay: { 
    type: Number, 
    default: 1 
  },
  stayDurationMinutes: { 
    type: Number, 
    default: 0 
  },
  stay10Claimed: { 
    type: Boolean, 
    default: false 
  },
  stay30Claimed: { 
    type: Boolean, 
    default: false 
  },
  giftSentCount: { 
    type: Number, 
    default: 0 
  },
  giftClaimed: { 
    type: Boolean, 
    default: false 
  },
  messagesSentCount: { 
    type: Number, 
    default: 0 
  },
  messageClaimed: { 
    type: Boolean, 
    default: false 
  },
  shareDone: { 
    type: Boolean, 
    default: false 
  },
  shareClaimed: { 
    type: Boolean, 
    default: false 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

userTaskSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('UserTask', userTaskSchema);
