const mongoose = require('mongoose');
const User = require('../models/user');
const ApiError = require('../utils/apiError');

class UserService {
  _computeAge(dob) {
    if (!dob) return null;
    const d = dob instanceof Date ? dob : new Date(dob);
    if (Number.isNaN(d.getTime())) return null;
    const now = new Date();
    let age = now.getFullYear() - d.getFullYear();
    const m = now.getMonth() - d.getMonth();
    if (m < 0 || (m === 0 && now.getDate() < d.getDate())) {
      age -= 1;
    }
    if (age < 0 || age > 150) return null;
    return age;
  }

  /**
   * Create a new user or update if exists
   * @param {string} phoneNumber - User's phone number
   * @param {Object} userData - Optional user data
   * @returns {Promise<Object>} - Created/updated user
   */
  async createOrUpdateUser(phoneNumber, userData = {}) {
    try {
      // Check if MongoDB is connected
      if (mongoose.connection.readyState !== 1) {
        // MongoDB not connected, return mock user
        return this._createMockUserResponse(phoneNumber, userData);
      }
      
      // Find user by phone number
      let user = await User.findOne({ phoneNumber });
      
      // If user doesn't exist, create new user
      if (!user) {
        user = new User({ phoneNumber });
      }

      // Aadhaar validation: mandatory 12 digits (especially for first-time profile completion).
      // Existing users who already have aadhaarNumber can update other fields without resending it.
      if (!user.aadhaarNumber) {
        const raw = (userData.aadhaarNumber ?? '').toString();
        const digitsOnly = raw.replace(/\D/g, '');
        if (!digitsOnly || digitsOnly.length !== 12) {
          throw new ApiError('INVALID_AADHAAR', 'Aadhaar number is required and must be exactly 12 digits', 400);
        }
        user.aadhaarNumber = digitsOnly;
      } else if (userData.aadhaarNumber !== undefined) {
        const raw = (userData.aadhaarNumber ?? '').toString();
        const digitsOnly = raw.replace(/\D/g, '');
        if (!digitsOnly || digitsOnly.length !== 12) {
          throw new ApiError('INVALID_AADHAAR', 'Aadhaar number must be exactly 12 digits', 400);
        }
        user.aadhaarNumber = digitsOnly;
      }
      
      // Update user fields if provided
      if (userData.name) user.name = userData.name;
      if (userData.email) user.email = userData.email;
      if (userData.dob) {
        const dob = userData.dob instanceof Date ? userData.dob : new Date(userData.dob);
        if (!Number.isNaN(dob.getTime())) {
          user.dob = dob;
          const age = this._computeAge(dob);
          if (age !== null) {
            user.age = age;
            user.ageGroup = undefined;
          }
        }
      }

      // Backward compatibility: allow clients to still send ageGroup.
      // If dob is present, dob-derived ageGroup takes priority.
      if (userData.ageGroup && !user.dob) user.ageGroup = userData.ageGroup;
      if (userData.emergencyContact) user.emergencyContact = userData.emergencyContact;
      
      // Calculate profile completeness
      user.calculateProfileCompleteness();
      
      // Save user
      await user.save();
      
      return {
        success: true,
        user: this._sanitizeUser(user)
      };
    } catch (error) {
      console.error('User creation/update failed:', error.message);
      throw new ApiError('USER_UPDATE_FAILED', 'Failed to update user profile', 500);
    }
  }
  
  /**
   * Get user profile by phone number
   * @param {string} phoneNumber - User's phone number
   * @returns {Promise<Object>} - User profile
   */
  async getUserProfile(phoneNumber) {
    try {
      const user = await User.findOne({ phoneNumber });
      
      if (!user) {
        throw new ApiError('USER_NOT_FOUND', 'User not found', 404);
      }
      
      return {
        success: true,
        user: this._sanitizeUser(user)
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('Get user profile failed:', error.message);
      throw new ApiError('USER_FETCH_FAILED', 'Failed to fetch user profile', 500);
    }
  }
  
  /**
   * Update user preferences
   * @param {string} phoneNumber - User's phone number
   * @param {Object} preferences - User preferences
   * @returns {Promise<Object>} - Updated user
   */
  async updatePreferences(phoneNumber, preferences) {
    try {
      let user = await User.findOne({ phoneNumber });
      
      if (!user) {
        user = new User({ phoneNumber });
      }
      
      // Update preferences
      if (preferences.seatPreference) {
        user.preferences.seatPreference = preferences.seatPreference;
      }
      
      if (preferences.trainClasses) {
        user.preferences.trainClasses = preferences.trainClasses;
      }
      
      if (preferences.dietaryPreference) {
        user.preferences.dietaryPreference = preferences.dietaryPreference;
      }
      
      if (preferences.specialAssistance !== undefined) {
        user.preferences.specialAssistance = preferences.specialAssistance;
      }
      
      // Calculate profile completeness
      user.calculateProfileCompleteness();
      
      // Save user
      await user.save();
      
      return {
        success: true,
        user: this._sanitizeUser(user)
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('Update preferences failed:', error.message);
      throw new ApiError('PREFERENCES_UPDATE_FAILED', 'Failed to update preferences', 500);
    }
  }
  
  /**
   * Update user verification status
   * @param {string} phoneNumber - User's phone number
   * @param {Object} verification - Verification data
   * @returns {Promise<Object>} - Updated user
   */
  async updateVerification(phoneNumber, verification) {
    try {
      const user = await User.findOne({ phoneNumber });
      
      if (!user) {
        throw new ApiError('USER_NOT_FOUND', 'User not found', 404);
      }
      
      // Update verification
      if (verification.idVerified !== undefined) {
        user.verification.idVerified = verification.idVerified;
      }
      
      if (verification.idType) {
        user.verification.idType = verification.idType;
      }
      
      if (verification.socialMediaLinked !== undefined) {
        user.verification.socialMediaLinked = verification.socialMediaLinked;
      }
      
      // Calculate profile completeness
      user.calculateProfileCompleteness();
      
      // Save user
      await user.save();
      
      return {
        success: true,
        user: this._sanitizeUser(user)
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('Update verification failed:', error.message);
      throw new ApiError('VERIFICATION_UPDATE_FAILED', 'Failed to update verification', 500);
    }
  }
  
  /**
   * Upload profile photo
   * @param {string} phoneNumber - User's phone number
   * @param {string} photoUrl - URL to uploaded photo
   * @returns {Promise<Object>} - Updated user
   */
  async updateProfilePhoto(phoneNumber, photoUrl) {
    try {
      const user = await User.findOne({ phoneNumber });
      
      if (!user) {
        throw new ApiError('USER_NOT_FOUND', 'User not found', 404);
      }
      
      // Update profile photo
      user.profilePhotoUrl = photoUrl;
      
      // Calculate profile completeness
      user.calculateProfileCompleteness();
      
      // Save user
      await user.save();
      
      return {
        success: true,
        user: this._sanitizeUser(user)
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('Update profile photo failed:', error.message);
      throw new ApiError('PHOTO_UPDATE_FAILED', 'Failed to update profile photo', 500);
    }
  }
  
  /**
   * Sanitize user object for client
   * @private
   * @param {Object} user - User document
   * @returns {Object} - Sanitized user object
   */
  _sanitizeUser(user) {
    const sanitized = user.toObject ? user.toObject() : user;
    
    // Remove sensitive fields
    delete sanitized.__v;
    
    return sanitized;
  }
  
  /**
   * Create a mock user response when MongoDB is not available
   * @private
   * @param {string} phoneNumber - User's phone number
   * @param {Object} userData - User data to include
   * @returns {Object} - Mock user response
   */
  _createMockUserResponse(phoneNumber, userData = {}) {
    console.log('Using mock user data due to MongoDB connection issue');
    
    // Create a mock user object with provided data
    const mockUser = {
      _id: 'mock_' + Date.now(),
      phoneNumber,
      aadhaarNumber: userData.aadhaarNumber || '',
      name: userData.name || '',
      email: userData.email || '',
      dob: userData.dob || null,
      age: userData.age || null,
      ageGroup: userData.ageGroup || '',
      emergencyContact: userData.emergencyContact || '',
      profileCompleteness: 20,
      preferences: {
        seatPreference: 'no preference',
        trainClasses: ['SL', '3A', '2A', '1A'],
        dietaryPreference: 'no preference',
        specialAssistance: false
      },
      verification: {
        idVerified: false,
        idType: 'none',
        socialMediaLinked: false
      },
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    return {
      success: true,
      user: mockUser,
      isMockData: true
    };
  }
}

module.exports = new UserService();
