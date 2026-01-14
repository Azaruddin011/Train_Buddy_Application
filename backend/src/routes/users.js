const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const { v2: cloudinary } = require('cloudinary');
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
      dob: req.body.dob,
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

cloudinary.config({ secure: true });

const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const mimetype = String(file.mimetype || '').toLowerCase();

    // Some devices/providers send non-standard image mimetypes.
    // Accept any image/* to reduce false negatives.
    if (mimetype.startsWith('image/')) {
      return cb(null, true);
    }

    // Fallback: occasionally images are sent as octet-stream.
    // We still reject unknown content-types unless the filename suggests a common image extension.
    const name = String(file.originalname || '').toLowerCase();
    const looksLikeImage = /\.(jpg|jpeg|png|webp|heic|heif)$/i.test(name);
    if (mimetype === 'application/octet-stream' && looksLikeImage) {
      return cb(null, true);
    }

    return cb(new ApiError('INVALID_PHOTO_TYPE', 'Only image files are allowed', 400));
  }
});

// Upload profile photo (multipart)
router.post('/photo', authMiddleware, extractPhoneNumber, upload.single('photo'), async (req, res, next) => {
  try {
    if (!req.file) {
      throw new ApiError('MISSING_PHOTO', 'Photo file is required', 400);
    }

    if (!process.env.CLOUDINARY_URL) {
      throw new ApiError('CLOUDINARY_NOT_CONFIGURED', 'Cloudinary is not configured', 500);
    }

    const safePhone = String(req.phoneNumber || 'user').replace(/[^0-9+]/g, '');
    const ext = path.extname(req.file.originalname || '').toLowerCase() || '.jpg';
    const publicId = `profile_${safePhone}_${Date.now()}${ext}`;

    const uploadResult = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: 'trainbuddy/profile_photos',
          public_id: publicId,
          resource_type: 'image'
        },
        (err, result) => {
          if (err) return reject(err);
          resolve(result);
        }
      );
      stream.end(req.file.buffer);
    });

    const photoUrl = uploadResult?.secure_url || uploadResult?.url;
    if (!photoUrl) {
      throw new ApiError('PHOTO_UPLOAD_FAILED', 'Failed to upload photo', 500);
    }

    const result = await userService.updateProfilePhoto(req.phoneNumber, photoUrl);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
