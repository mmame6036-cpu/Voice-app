const express = require('express');
const router = express.Router();
const Payment = require('../models/Payment');
const User = require('../models/User');

// 1. ተጠቃሚው የከፈለበትን Transaction ID ሲልክ
router.post('/recharge-request', async (req, res) => {
  try {
    const { userId, userName, paymentMethod, txId, amountCoins, pricePaid } = req.body;

    if (!userId  !txId  !amountCoins) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const existingTx = await Payment.findOne({ txId });
    if (existingTx) {
      return res.status(400).json({ success: false, message: 'Transaction ID already submitted' });
    }

    const newPayment = new Payment({
      userId,
      userName,
      paymentMethod,
      txId,
      amountCoins,
      pricePaid,
      status: 'pending',
    });

    await newPayment.save();
    res.json({ success: true, message: 'Recharge request submitted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. አድሚን ገብቶ ያልተረጋገጡትን (Pending) ክፍያዎች ዝርዝር የሚያይበት
router.get('/admin/pending-payments', async (req, res) => {
  try {
    const pendings = await Payment.find({ status: 'pending' }).sort({ createdAt: -1 });
    res.json({ success: true, data: pendings });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 3. አድሚኑ "Approve" ሲነካ ሳንቲሙን ወዲያውኑ ወደ ተጠቃሚው አካውንት መጨመር
router.post('/admin/approve-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

    const payment = await Payment.findById(paymentId);
    if (!payment || payment.status !== 'pending') {
      return res.status(400).json({ success: false, message: 'Invalid or already processed payment' });
    }

    // የተጠቃሚውን ሳንቲም በዳታቤዝ ውስጥ መጨመር
    const user = await User.findOneAndUpdate(
      { userId: payment.userId },
      { $inc: { coins: payment.amountCoins } },
      { new: true }
    );

    payment.status = 'approved';
    await payment.save();

    res.json({
      success: true,
      message: 'Payment approved and coins added successfully',
      updatedCoins: user ? user.coins : null,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
