const express = require('express');
const router = express.Router();

const mongoose = require('mongoose');

const auth = require('../middleware/auth');
const requireVerifiedPnr = require('../middleware/requireVerifiedPnr');
const ApiError = require('../utils/apiError');

const OfferSeat = require('../models/offerSeat');
const OfferSeatRequest = require('../models/offerSeatRequest');

function ensurePremium(req, res, next) {
  const hasPremium = true;
  if (!hasPremium) {
    return res.status(403).json({
      success: false,
      errorCode: 'PREMIUM_REQUIRED',
      message: 'Premium is required.'
    });
  }
  next();
}

function getPhoneNumber(req) {
  return (req.user?.phoneNumber || req.user?.phone || '').toString().trim();
}

function maskPhone(phoneNumber) {
  const raw = (phoneNumber || '').toString();
  const digits = raw.replace(/\D/g, '');
  if (digits.length < 4) return 'Passenger';
  return 'Passenger • ' + digits.slice(-4);
}

function pickStatusFromAction(action) {
  const a = String(action || '').toUpperCase();
  if (a === 'ACCEPT') return 'ACCEPTED';
  if (a === 'REJECT' || a === 'DECLINE' || a === 'IGNORE') return 'REJECTED';
  if (a === 'CANCEL') return 'CANCELLED';
  return null;
}

router.post('/create', auth, requireVerifiedPnr(), ensurePremium, async (req, res, next) => {
  try {
    const { pnr, seatsAvailable, note } = req.body;
    if (!pnr) {
      throw new ApiError('INVALID_INPUT', 'PNR is required.', 400);
    }

    if (mongoose.connection.readyState !== 1) {
      throw new ApiError('DB_UNAVAILABLE', 'Database is unavailable', 503);
    }

    const phoneNumber = getPhoneNumber(req);
    const v = req.verifiedJourney;
    const j = v?.journey || {};

    if (v?.statusType !== 'CNF') {
      throw new ApiError('PNR_NOT_CONFIRMED', 'Only confirmed (CNF) passengers can offer seats.', 403);
    }

    const nSeatsRaw = parseInt(seatsAvailable, 10);
    const nSeats = Number.isFinite(nSeatsRaw) ? Math.min(Math.max(nSeatsRaw, 1), 4) : 1;

    const doc = await OfferSeat.findOneAndUpdate(
      { phoneNumber, pnr },
      {
        $setOnInsert: { phoneNumber, pnr },
        $set: {
          journey: j,
          seatsAvailable: nSeats,
          note: note ? String(note).trim() : undefined,
          status: 'ACTIVE',
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.json({
      success: true,
      offer: {
        id: String(doc._id),
        status: doc.status,
      }
    });
  } catch (err) {
    next(err);
  }
});

router.get('/search', auth, requireVerifiedPnr({ getPnr: (req) => req.query?.pnr }), ensurePremium, async (req, res, next) => {
  try {
    if (mongoose.connection.readyState !== 1) {
      throw new ApiError('DB_UNAVAILABLE', 'Database is unavailable', 503);
    }

    const phoneNumber = getPhoneNumber(req);
    const v = req.verifiedJourney;
    const j = v?.journey || {};
    if (!j.trainNumber || !j.class || !j.boardingDate) {
      throw new ApiError('JOURNEY_MISSING', 'Verified journey details missing. Please re-check PNR.', 400);
    }

    const offers = await OfferSeat.find({
      phoneNumber: { $ne: phoneNumber },
      'journey.trainNumber': j.trainNumber,
      'journey.class': j.class,
      'journey.boardingDate': j.boardingDate,
      status: 'ACTIVE',
    })
      .sort({ updatedAt: -1 })
      .limit(50)
      .lean();

    const result = offers.map((o) => ({
      id: String(o._id),
      displayName: maskPhone(o.phoneNumber),
      from: (o.journey?.from || '').toString(),
      to: (o.journey?.to || '').toString(),
      trainNumber: (o.journey?.trainNumber || '').toString(),
      trainClass: (o.journey?.class || '').toString(),
      boardingDate: (o.journey?.boardingDate || '').toString(),
      seatsAvailable: o.seatsAvailable || 1,
      note: o.note || '',
    }));

    res.json({ success: true, offers: result });
  } catch (err) {
    next(err);
  }
});

router.post('/request', auth, requireVerifiedPnr(), ensurePremium, async (req, res, next) => {
  try {
    const { pnr, offerId, message } = req.body;
    if (!pnr || !offerId) {
      throw new ApiError('INVALID_INPUT', 'PNR and offerId are required.', 400);
    }

    if (mongoose.connection.readyState !== 1) {
      throw new ApiError('DB_UNAVAILABLE', 'Database is unavailable', 503);
    }

    const fromPhoneNumber = getPhoneNumber(req);
    const offer = await OfferSeat.findById(offerId);
    if (!offer) {
      throw new ApiError('OFFER_NOT_FOUND', 'Offer not found', 404);
    }
    if (offer.status !== 'ACTIVE') {
      throw new ApiError('OFFER_NOT_ACTIVE', 'Offer is not active', 400);
    }
    if (offer.phoneNumber === fromPhoneNumber) {
      throw new ApiError('INVALID_REQUEST', 'Cannot request your own offer', 400);
    }

    const my = req.verifiedJourney;
    const j = my?.journey || {};
    const oj = offer.journey || {};
    const sameTrip =
      String(oj.trainNumber || '') === String(j.trainNumber || '') &&
      String(oj.class || '') === String(j.class || '') &&
      String(oj.boardingDate || '') === String(j.boardingDate || '');
    if (!sameTrip) {
      throw new ApiError('TRIP_MISMATCH', 'Offer is not on your same train/class/date', 400);
    }

    const toPhoneNumber = offer.phoneNumber;

    const doc = await OfferSeatRequest.findOneAndUpdate(
      { offerId: offer._id, fromPhoneNumber },
      {
        $setOnInsert: { offerId: offer._id, fromPhoneNumber, toPhoneNumber, pnr },
        $set: {
          status: 'PENDING',
          message: message ? String(message).trim() : undefined,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.json({
      success: true,
      request: {
        id: String(doc._id),
        status: doc.status,
      }
    });
  } catch (err) {
    next(err);
  }
});

router.post('/respond', auth, async (req, res, next) => {
  try {
    const { requestId, action } = req.body;
    if (!requestId || !action) {
      throw new ApiError('INVALID_INPUT', 'requestId and action are required.', 400);
    }

    if (mongoose.connection.readyState !== 1) {
      throw new ApiError('DB_UNAVAILABLE', 'Database is unavailable', 503);
    }

    const status = pickStatusFromAction(action);
    if (!status) {
      throw new ApiError('INVALID_ACTION', 'Action must be ACCEPT, REJECT, or CANCEL', 400);
    }

    const phoneNumber = getPhoneNumber(req);
    const doc = await OfferSeatRequest.findById(requestId);
    if (!doc) {
      throw new ApiError('REQUEST_NOT_FOUND', 'Offer request not found', 404);
    }

    const isReceiver = doc.toPhoneNumber === phoneNumber;
    const isSender = doc.fromPhoneNumber === phoneNumber;

    if ((status === 'ACCEPTED' || status === 'REJECTED') && !isReceiver) {
      throw new ApiError('FORBIDDEN', 'Only the offer owner can accept/reject this request', 403);
    }
    if (status === 'CANCELLED' && !isSender) {
      throw new ApiError('FORBIDDEN', 'Only the requester can cancel this request', 403);
    }

    doc.status = status;
    await doc.save();

    res.json({
      success: true,
      request: {
        id: String(doc._id),
        status: doc.status,
      }
    });
  } catch (err) {
    next(err);
  }
});

router.get('/requests/incoming', auth, requireVerifiedPnr({ getPnr: (req) => req.query?.pnr }), ensurePremium, async (req, res, next) => {
  try {
    const phoneNumber = getPhoneNumber(req);
    const pnr = (req.query?.pnr || '').toString().trim();

    const items = await OfferSeatRequest.find({ toPhoneNumber: phoneNumber, pnr })
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();

    res.json({ success: true, requests: items });
  } catch (err) {
    next(err);
  }
});

router.get('/requests/outgoing', auth, requireVerifiedPnr({ getPnr: (req) => req.query?.pnr }), ensurePremium, async (req, res, next) => {
  try {
    const phoneNumber = getPhoneNumber(req);
    const pnr = (req.query?.pnr || '').toString().trim();

    const items = await OfferSeatRequest.find({ fromPhoneNumber: phoneNumber, pnr })
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();

    res.json({ success: true, requests: items });
  } catch (err) {
    next(err);
  }
});

router.get('/my', auth, requireVerifiedPnr({ getPnr: (req) => req.query?.pnr }), ensurePremium, async (req, res, next) => {
  try {
    const phoneNumber = getPhoneNumber(req);
    const pnr = (req.query?.pnr || '').toString().trim();

    const offer = await OfferSeat.findOne({ phoneNumber, pnr }).lean();
    res.json({
      success: true,
      offer: offer ? { ...offer, id: String(offer._id) } : null,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
