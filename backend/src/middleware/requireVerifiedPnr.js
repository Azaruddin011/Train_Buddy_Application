const mongoose = require('mongoose');
const ApiError = require('../utils/apiError');
const VerifiedJourney = require('../models/verifiedJourney');

function getPhoneNumber(req) {
  const v = req?.user?.phoneNumber || req?.user?.phone;
  return (v || '').toString().trim();
}

module.exports = function requireVerifiedPnr(options = {}) {
  const {
    getPnr = (req) => req.body?.pnr || req.query?.pnr,
  } = options;

  return async function (req, res, next) {
    try {
      const phoneNumber = getPhoneNumber(req);
      if (!phoneNumber) {
        return next(new ApiError('UNAUTHORIZED', 'Missing user context', 401));
      }

      const pnr = (getPnr(req) || '').toString().trim();
      if (!pnr || pnr.length !== 10) {
        return next(new ApiError('INVALID_PNR', 'A valid 10-digit PNR is required', 400));
      }

      if (mongoose.connection.readyState !== 1) {
        return next(new ApiError('VERIFICATION_UNAVAILABLE', 'Verification service is temporarily unavailable', 503));
      }

      const doc = await VerifiedJourney.findOne({ phoneNumber, pnr }).lean();
      if (!doc) {
        return next(new ApiError('PNR_NOT_VERIFIED', 'Please verify your PNR before using this feature', 403));
      }

      req.verifiedJourney = doc;
      return next();
    } catch (err) {
      return next(err);
    }
  };
};
