const mongoose = require('mongoose');

const offerSeatSchema = new mongoose.Schema({
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
  seatsAvailable: {
    type: Number,
    default: 1,
    min: 1,
    max: 4,
  },
  note: {
    type: String,
    trim: true,
  },
  status: {
    type: String,
    enum: ['ACTIVE', 'PAUSED', 'CLOSED'],
    default: 'ACTIVE',
    index: true,
  },
}, {
  timestamps: true,
});

offerSeatSchema.index({ phoneNumber: 1, pnr: 1 }, { unique: true });

const OfferSeat = mongoose.model('OfferSeat', offerSeatSchema);

module.exports = OfferSeat;
