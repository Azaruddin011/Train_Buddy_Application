const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

router.post('/create-intent', auth, (req, res) => {
  const { pnr } = req.body;
  if (!pnr) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_INPUT',
      message: 'PNR is required.'
    });
  }

  return res.json({
    success: true,
    payment: {
      id: 'pay_123',
      amount: 39900,
      currency: 'INR',
      status: 'PENDING',
      providerOrderId: 'provider_order_abc'
    }
  });
});

router.post('/confirm', auth, (req, res) => {
  const { paymentId, providerPaymentId, providerSignature } = req.body;
  if (!paymentId || !providerPaymentId || !providerSignature) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_INPUT',
      message: 'Missing payment confirmation fields.'
    });
  }

  return res.json({
    success: true,
    payment: {
      id: paymentId,
      status: 'SUCCESS'
    },
    premium: {
      active: true,
      pnr: '1234567890'
    }
  });
});

module.exports = router;
