const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  userName: { type: String, default: '' },
  paymentMethod: { type: String, enum: ['Telebirr', 'Binance'], required: true },
  txId: { type: String, required: true, unique: true },
  amountCoins: { type: Number, required: true },
  pricePaid: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Payment', paymentSchema);
