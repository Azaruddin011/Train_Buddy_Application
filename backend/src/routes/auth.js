const express = require('express');
const router = express.Router();

const jwt = require('jsonwebtoken');
const twilio = require('twilio');

function normalizeIndianPhone(input) {
  const raw = String(input || '').trim();
  if (!raw) return null;

  // Accept +91XXXXXXXXXX or 10 digit local.
  if (/^\+91\d{10}$/.test(raw)) return raw;
  if (/^\d{10}$/.test(raw)) return `+91${raw}`;

  // Fall back: strip non-digits and try again.
  const digits = raw.replace(/\D/g, '');
  if (digits.length === 10) return `+91${digits}`;
  if (digits.length === 12 && digits.startsWith('91')) return `+${digits}`;
  return null;
}

function getTwilioClient() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  if (!accountSid || !authToken) {
    throw new Error('Twilio credentials not configured');
  }
  return twilio(accountSid, authToken);
}

function getVerifyServiceSid() {
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
  if (!serviceSid) {
    throw new Error('TWILIO_VERIFY_SERVICE_SID not configured');
  }
  return serviceSid;
}

function signAppToken(payload) {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET not configured');
  }
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
  return jwt.sign(payload, secret, { expiresIn });
}

router.post('/send-otp', (req, res) => {
  (async () => {
    const { phone } = req.body;
    const to = normalizeIndianPhone(phone);
    if (!to) {
      return res.status(400).json({
        success: false,
        errorCode: 'INVALID_PHONE',
        message: 'Enter a valid 10-digit phone number.'
      });
    }

    try {
      const client = getTwilioClient();
      const serviceSid = getVerifyServiceSid();

      await client.verify.v2
        .services(serviceSid)
        .verifications.create({ to, channel: 'sms' });

      return res.json({
        success: true,
        message: 'OTP sent'
      });
    } catch (error) {
      const status = error?.status || error?.statusCode || error?.response?.status;
      const code = error?.code || error?.moreInfo || error?.response?.data?.code;
      const details = error?.details || error?.response?.data || null;
      console.error('Twilio send-otp failed:', {
        message: error?.message,
        status,
        code,
        details
      });
      return res.status(500).json({
        success: false,
        errorCode: 'OTP_SEND_FAILED',
        message: 'Failed to send OTP. Check Twilio credentials, Verify Service SID, and trial verified numbers.'
      });
    }
  })();
});

router.post('/verify-otp', (req, res) => {
  (async () => {
    const { phone, otp } = req.body;
    const to = normalizeIndianPhone(phone);

    if (!to || !otp) {
      return res.status(400).json({
        success: false,
        errorCode: 'INVALID_INPUT',
        message: 'Phone and OTP are required.'
      });
    }

    try {
      const client = getTwilioClient();
      const serviceSid = getVerifyServiceSid();

      const check = await client.verify.v2
        .services(serviceSid)
        .verificationChecks.create({ to, code: String(otp).trim() });

      if (check.status !== 'approved') {
        return res.status(401).json({
          success: false,
          errorCode: 'OTP_INVALID',
          message: 'Invalid OTP.'
        });
      }

      const token = signAppToken({ phone: to, phoneNumber: to });

      return res.json({
        success: true,
        token,
        user: {
          phone: to
        }
      });
    } catch (error) {
      const status = error?.status || error?.statusCode || error?.response?.status;
      const code = error?.code || error?.moreInfo || error?.response?.data?.code;
      const details = error?.details || error?.response?.data || null;
      console.error('Twilio verify-otp failed:', {
        message: error?.message,
        status,
        code,
        details
      });
      return res.status(500).json({
        success: false,
        errorCode: 'OTP_VERIFY_FAILED',
        message: 'Failed to verify OTP. Please try again.'
      });
    }
  })();
});

module.exports = router;
