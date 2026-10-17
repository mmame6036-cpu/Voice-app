const mongoose = require('mongoose');

const agencyHostSchema = new mongoose.Schema({
  agencyId: { 
    type: String, 
    required: true 
  },
  userId: { 
    type: String, 
    required: true, 
    unique: true 
  },
  userName: { 
    type: String, 
    default: 'Host' 
  },
  avatar: { 
    type: String, 
    default: '' 
  },
  status: { 
    type: String, 
    enum: ['pending', 'active', 'rejected', 'terminated'], 
    default: 'pending' 
  },
  monthlyTargetPoints: { 
    type: Number, 
    default: 50000 
  },
  currentMonthPoints: { 
    type: Number, 
    default: 0 
  },
  validDays: { 
    type: Number, 
    default: 0 
  },
  validHours: { 
    type: Number, 
    default: 0 
  },
  joinedAt: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('AgencyHost', agencyHostSchema);
