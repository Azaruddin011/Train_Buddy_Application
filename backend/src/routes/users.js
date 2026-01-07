const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const userService = require('../services/userService');
const authMiddleware = require('../middleware/auth');
const ApiError = require('../utils/apiError');

// Middleware to extract phone number from token
const extractPhoneNumber = (req, res, next) => {
  // In a real app, this would come from the decoded JWT
  // For now, we'll use a placeholder or query param
  req.phoneNumber = req.user?.phoneNumber || req.user?.phone || req.query.phoneNumber || req.body.phoneNumber;
  
  if (!req.phoneNumber) {
    return next(new ApiError('MISSING_PHONE', 'Phone number is required', 400));
  }
  
  next();
};

// Get user profile
router.get('/profile', authMiddleware, extractPhoneNumber, async (req, res, next) => {
  try {
    const result = await userService.getUserProfile(req.phoneNumber);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

// Update basic profile
router.post('/profile', authMiddleware, extractPhoneNumber, async (req, res, next) => {
  try {
    const userData = {
      name: req.body.name,
      email: req.body.email,
      ageGroup: req.body.ageGroup,
      emergencyContact: req.body.emergencyContact,
      aadhaarNumber: req.body.aadhaarNumber
    };
    
    const result = await userService.createOrUpdateUser(req.phoneNumber, userData);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

// Update preferences
router.post('/preferences', authMiddleware, extractPhoneNumber, async (req, res, next) => {
  try {
    const preferences = {
      seatPreference: req.body.seatPreference,
      trainClasses: req.body.trainClasses,
      dietaryPreference: req.body.dietaryPreference,
      specialAssistance: req.body.specialAssistance
    };
    
    const result = await userService.updatePreferences(req.phoneNumber, preferences);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

// Update verification
router.post('/verification', authMiddleware, extractPhoneNumber, async (req, res, next) => {
  try {
    const verification = {
      idVerified: req.body.idVerified,
      idType: req.body.idType,
      socialMediaLinked: req.body.socialMediaLinked
    };
    
    const result = await userService.updateVerification(req.phoneNumber, verification);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

const uploadsDir = path.join(__dirname, '..', '..', 'uploads');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    try {
      fs.mkdirSync(uploadsDir, { recursive: true });
    } catch (_) {
      // ignore
    }
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const safePhone = String(req.phoneNumber || 'user').replace(/[^0-9+]/g, '');
    const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
    cb(null, `profile_${safePhone}_${Date.now()}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']);
    if (!allowed.has(file.mimetype)) {
      return cb(new ApiError('INVALID_PHOTO_TYPE', 'Only JPG, PNG, WEBP, or HEIC images are allowed', 400));
    }
    cb(null, true);
  }
});

// Upload profile photo (multipart)
router.post('/photo', authMiddleware, extractPhoneNumber, upload.single('photo'), async (req, res, next) => {
  try {
    if (!req.file) {
      throw new ApiError('MISSING_PHOTO', 'Photo file is required', 400);
    }

    const photoUrl = `/uploads/${req.file.filename}`;
    
    const result = await userService.updateProfilePhoto(req.phoneNumber, photoUrl);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
