const mongoose = require('mongoose');

const buddyRequestSchema = new mongoose.Schema({
  fromPhoneNumber: {
    type: String,
    required: true,
    trim: true,
    index: true,
  },
  toPhoneNumber: {
    type: String,
    required: true,
    trim: true,
    index: true,
  },
  pnr: {
    type: String,
    required: true,
    trim: true,
    index: true,
  },
  message: {
    type: String,
    trim: true,
  },
  status: {
    type: String,
    enum: ['PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED'],
    default: 'PENDING',
    index: true,
  },
}, {
  timestamps: true,
});

buddyRequestSchema.index(
  { fromPhoneNumber: 1, toPhoneNumber: 1, pnr: 1 },
  { unique: true }
);

const BuddyRequest = mongoose.model('BuddyRequest', buddyRequestSchema);

module.exports = BuddyRequest;
