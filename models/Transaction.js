const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: { 
    type: String, 
    required: true 
  },
  type: { 
    type: String, 
    required: true 
  },
  amount: { 
    type: Number, 
    required: true 
  },
  balanceAfter: { 
    type: Number, 
    default: 0 
  },
  description: { 
    type: String, 
    default: '' 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Transaction', transactionSchema);
