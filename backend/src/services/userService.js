const User = require('../models/user');
const ApiError = require('../utils/apiError');

class UserService {
  /**
   * Create a new user or update if exists
   * @param {string} phoneNumber - User's phone number
   * @param {Object} userData - Optional user data
   * @returns {Promise<Object>} - Created/updated user
   */
  async createOrUpdateUser(phoneNumber, userData = {}) {
    try {
      // Find user by phone number
      let user = await User.findOne({ phoneNumber });
      
      // If user doesn't exist, create new user
      if (!user) {
        user = new User({ phoneNumber });
      }
      
      // Update user fields if provided
      if (userData.name) user.name = userData.name;
      if (userData.email) user.email = userData.email;
      if (userData.ageGroup) user.ageGroup = userData.ageGroup;
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
      const user = await User.findOne({ phoneNumber });
      
      if (!user) {
        throw new ApiError('USER_NOT_FOUND', 'User not found', 404);
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
    const sanitized = user.toObject();
    
    // Remove sensitive fields
    delete sanitized.__v;
    
    return sanitized;
  }
}

module.exports = new UserService();
