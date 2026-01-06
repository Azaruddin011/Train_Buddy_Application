const mongoose = require('mongoose');

const offerSeatRequestSchema = new mongoose.Schema({
  offerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'OfferSeat',
    required: true,
    index: true,
  },
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

offerSeatRequestSchema.index(
  { offerId: 1, fromPhoneNumber: 1 },
  { unique: true }
);

const OfferSeatRequest = mongoose.model('OfferSeatRequest', offerSeatRequestSchema);

module.exports = OfferSeatRequest;
