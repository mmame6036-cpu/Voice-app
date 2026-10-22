const mongoose = require('mongoose');

const agencyHostSchema = new mongoose.Schema({
  agencyId: { type: String, required: true, index: true },
  userId: { type: String, required: true, unique: true },
  userName: { type: String, default: '' },
  avatar: { type: String, default: '' },
  status: { 
    type: String, 
    enum: ['active', 'pending', 'rejected', 'terminated'], 
    default: 'pending' 
  },
  currentMonthPoints: { type: Number, default: 0 },
  validHours: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('AgencyHost', agencyHostSchema);
