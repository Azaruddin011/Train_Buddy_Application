const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  name: {
    type: String,
    trim: true,
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
  },
  ageGroup: {
    type: String,
    enum: ['Under 18', '18-25', '26-35', '36-50', 'Above 50'],
  },
  profilePhotoUrl: {
    type: String,
  },
  emergencyContact: {
    type: String,
    trim: true,
  },
  preferences: {
    seatPreference: {
      type: String,
      enum: ['window', 'aisle', 'no preference'],
      default: 'no preference',
    },
    trainClasses: {
      type: [String],
      default: ['SL', '3A', '2A', '1A'],
    },
    dietaryPreference: {
      type: String,
      enum: ['vegetarian', 'non-vegetarian', 'no preference'],
      default: 'no preference',
    },
    specialAssistance: {
      type: Boolean,
      default: false,
    },
  },
  verification: {
    idVerified: {
      type: Boolean,
      default: false,
    },
    idType: {
      type: String,
      enum: ['aadhaar', 'pan', 'driving_license', 'none'],
      default: 'none',
    },
    socialMediaLinked: {
      type: Boolean,
      default: false,
    },
  },
  profileCompleteness: {
    type: Number,
    default: 0, // 0-100%
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update the updatedAt timestamp before saving
userSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Calculate profile completeness
userSchema.methods.calculateProfileCompleteness = function() {
  let completeness = 0;
  const totalFields = 8; // Total number of profile fields we're tracking
  
  // Basic info - 50% of total
  if (this.name) completeness += 12.5;
  if (this.email) completeness += 12.5;
  if (this.ageGroup) completeness += 12.5;
  if (this.profilePhotoUrl) completeness += 12.5;
  
  // Emergency contact - 12.5%
  if (this.emergencyContact) completeness += 12.5;
  
  // Preferences - 25%
  if (this.preferences.seatPreference !== 'no preference') completeness += 6.25;
  if (this.preferences.dietaryPreference !== 'no preference') completeness += 6.25;
  if (this.preferences.trainClasses.length < 4) completeness += 12.5; // If they've customized classes
  
  // Verification - 12.5%
  if (this.verification.idVerified) completeness += 6.25;
  if (this.verification.socialMediaLinked) completeness += 6.25;
  
  this.profileCompleteness = Math.min(Math.round(completeness), 100);
  return this.profileCompleteness;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
