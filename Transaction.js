const mongoose = require('mongoose');

// ነጥብ 2፡ የሳንቲም እንቅስቃሴ ታሪክ ማስታወሻ ሞዴል (Ledger)
const transactionSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  type: { 
    type: String, 
    enum: ['game_bet', 'game_win', 'gift_sent', 'gift_received', 'recharge'], 
    required: true 
  },
  amount: { type: Number, required: true },
  balanceAfter: { type: Number, required: true },
  description: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Transaction', transactionSchema);
