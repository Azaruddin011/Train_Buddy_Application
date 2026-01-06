const mongoose = require('mongoose');

const verifiedJourneySchema = new mongoose.Schema({
  phoneNumber: {
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
  journey: {
    trainNumber: { type: String, trim: true },
    trainName: { type: String, trim: true },
    class: { type: String, trim: true },
    from: { type: String, trim: true },
    to: { type: String, trim: true },
    boardingDate: { type: String, trim: true },
  },
  statusType: {
    type: String,
    trim: true,
  },
  verifiedAt: {
    type: Date,
    default: Date.now,
    index: true,
  },
}, {
  timestamps: true,
});

verifiedJourneySchema.index({ phoneNumber: 1, pnr: 1 }, { unique: true });

const VerifiedJourney = mongoose.model('VerifiedJourney', verifiedJourneySchema);

module.exports = VerifiedJourney;
