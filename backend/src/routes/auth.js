const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const OTP = require('../models/otp');

const JWT_SECRET = process.env.JWT_SECRET || 'trainbuddy_secret_key_change_in_production';

router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone || phone.length !== 10) {
      return res.status(400).json({
        success: false,
        errorCode: 'INVALID_PHONE',
        message: 'Enter a valid 10-digit phone number.'
      });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Save OTP to database (expires in 5 minutes)
    await OTP.findOneAndUpdate(
      { phoneNumber: phone },
      { phoneNumber: phone, otp: otp },
      { upsert: true, new: true }
    );

    // In production, send OTP via SMS service (Twilio, AWS SNS, etc.)
    console.log(`📱 OTP for ${phone}: ${otp}`);

    return res.json({
      success: true,
      message: 'OTP sent successfully',
      retryAfterSeconds: 60,
      // Remove this in production - only for testing
      otp: process.env.NODE_ENV === 'development' ? otp : undefined
    });
  } catch (error) {
    console.error('Send OTP error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'SERVER_ERROR',
      message: 'Failed to send OTP'
    });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        errorCode: 'INVALID_INPUT',
        message: 'Phone and OTP are required.'
      });
    }

    // Find OTP in database
    const otpRecord = await OTP.findOne({ phoneNumber: phone });
    
    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        errorCode: 'OTP_NOT_FOUND',
        message: 'OTP expired or not found. Please request a new OTP.'
      });
    }

    // Verify OTP
    if (otpRecord.otp !== otp) {
      return res.status(400).json({
        success: false,
        errorCode: 'INVALID_OTP',
        message: 'Invalid OTP. Please try again.'
      });
    }

    // OTP is valid - delete it
    await OTP.deleteOne({ phoneNumber: phone });

    // Find or create user
    let user = await User.findOne({ phoneNumber: phone });
    let isNewUser = false;
    
    if (!user) {
      user = await User.create({
        phoneNumber: phone
      });
      isNewUser = true;
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, phoneNumber: user.phoneNumber },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.json({
      success: true,
      token,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        name: user.name,
        email: user.email,
        profilePhoto: user.profilePhoto,
        profileCompleteness: user.profileCompleteness
      },
      isNewUser
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'SERVER_ERROR',
      message: 'Failed to verify OTP'
    });
  }
});

module.exports = router;
