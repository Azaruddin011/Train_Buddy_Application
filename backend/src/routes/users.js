const express = require('express');
const router = express.Router();
const userService = require('../services/userService');
const authMiddleware = require('../middleware/auth');
const ApiError = require('../utils/apiError');

// Middleware to extract phone number from token
const extractPhoneNumber = (req, res, next) => {
  // In a real app, this would come from the decoded JWT
  // For now, we'll use a placeholder or query param
  req.phoneNumber = req.query.phoneNumber || req.body.phoneNumber;
  
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
      emergencyContact: req.body.emergencyContact
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

// Upload profile photo (placeholder - would normally use multer for file uploads)
router.post('/photo', authMiddleware, extractPhoneNumber, async (req, res, next) => {
  try {
    // In a real implementation, we'd handle file upload and get a URL
    // For now, we'll just use a URL provided in the request
    const photoUrl = req.body.photoUrl;
    
    if (!photoUrl) {
      throw new ApiError('MISSING_PHOTO', 'Photo URL is required', 400);
    }
    
    const result = await userService.updateProfilePhoto(req.phoneNumber, photoUrl);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
