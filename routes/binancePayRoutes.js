const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const axios = require('axios');
const User = require('../models/User'); // የ MongoDB ተጠቃሚ ሞዴል

const BINANCE_API_KEY = process.env.BINANCE_PAY_API_KEY || 'YOUR_BINANCE_API_KEY';
const BINANCE_SECRET_KEY = process.env.BINANCE_PAY_SECRET_KEY || 'YOUR_BINANCE_SECRET_KEY';
const BASE_URL = 'https://bpay.binanceapi.com';

function hashSignature(queryString, secret) {
  return crypto.createHmac('sha512', secret).update(queryString).digest('hex').toUpperCase();
}

// 1. የክፍያ ትዕዛዝ ማመንጫ
router.post('/create-order', async (req, res) => {
  try {
    const { userId, amount, coins } = req.body;
    const orderId = BPAY_${Date.now()}_${userId}_${coins};
    const nonce = crypto.randomBytes(16).toString('hex');
    const timestamp = Date.now().toString();

    const body = {
      env: { terminalType: 'APP' },
      merchantTradeNo: orderId,
      orderAmount: parseFloat(amount).toFixed(2),
      currency: 'USDT',
      goods: {
        goodsType: '02',
        goodsCategory: 'Z000',
        referenceGoodsId: orderId,
        goodsName: ${coins} Coins,
        goodsDetail: Purchase of ${coins} voice chat coins
      }
    };

    const jsonPayload = JSON.stringify(body);
    const payloadToSign = ${timestamp}\n${nonce}\n${jsonPayload}\n;
    const signature = hashSignature(payloadToSign, BINANCE_SECRET_KEY);

    const headers = {
      'content-type': 'application/json',
      'BinancePay-Timestamp': timestamp,
      'BinancePay-Nonce': nonce,
      'BinancePay-Certificate-SN': BINANCE_API_KEY,
      'BinancePay-Signature': signature
    };

    const response = await axios.post(${BASE_URL}/binancepay/openapi/v2/order, body, { headers });

    if (response.data.status === 'SUCCESS') {
      return res.json({
        success: true,
        checkoutUrl: response.data.data.checkoutUrl,
        deeplink: response.data.data.deeplink,
        orderId: orderId
      });
    }

    res.status(400).json({ success: false, message: response.data.errorMessage });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. የክፍያ ማረጋገጫ Webhook (አውቶማቲክ ኮይን መጨመሪያ)
router.post('/webhook', async (req, res) => {
  try {
    const { bizStatus, data } = req.body;

    if (bizStatus === 'PAY_SUCCESS') {
      const parsedData = typeof data === 'string' ? JSON.parse(data) : data;
      const tradeNo = parsedData.merchantTradeNo;
      
      // ትዕዛዙን በመበተን User ID እና Coins ማግኘት: BPAY_timestamp_userId_coins
      const parts = tradeNo.split('_');
      const userId = parts[2];
      const coinsToAdd = parseInt(parts[3], 10);

      if (userId && coinsToAdd) {
        await User.updateOne(
          { userId: userId },
          { $inc: { coins: coinsToAdd } }
        );
      }
    }

    res.json({ returnCode: 'SUCCESS', returnMessage: null });
  } catch (err) {
    res.status(500).json({ returnCode: 'FAIL', returnMessage: err.message });
  }
});

module.exports = router;
