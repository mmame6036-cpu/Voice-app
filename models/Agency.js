const mongoose = require('mongoose');

const agencySchema = new mongoose.Schema({
  agencyId: { 
    type: String, 
    required: true, 
    unique: true 
  },
  ownerId: { 
    type: String, 
    required: true 
  },
  agencyName: { 
    type: String, 
    required: true 
  },
  logo: { 
    type: String, 
    default: '' 
  },
  level: { 
    type: Number, 
    default: 1 
  },
  commissionRate: { 
    type: Number, 
    default: 10 
  },
  totalEarnings: { 
    type: Number, 
    default: 0 
  },
  balancePoints: { 
    type: Number, 
    default: 0 
  },
  status: { 
    type: String, 
    enum: ['active', 'suspended', 'pending'], 
    default: 'active' 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Agency', agencySchema);
