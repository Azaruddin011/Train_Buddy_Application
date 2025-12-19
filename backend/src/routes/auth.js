const express = require('express');
const router = express.Router();

router.post('/send-otp', (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PHONE',
      message: 'Enter a valid phone number.'
    });
  }

  return res.json({
    success: true,
    message: 'OTP sent',
    retryAfterSeconds: 60
  });
});

router.post('/verify-otp', (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_INPUT',
      message: 'Phone and OTP are required.'
    });
  }

  return res.json({
    success: true,
    token: 'MOCK_JWT_TOKEN',
    user: {
      id: 'user_123',
      phone
    }
  });
});

module.exports = router;
