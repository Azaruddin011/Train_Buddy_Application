const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireVerifiedPnr = require('../middleware/requireVerifiedPnr');
const mongoose = require('mongoose');
const ApiError = require('../utils/apiError');
const VerifiedJourney = require('../models/verifiedJourney');
const BuddyRequest = require('../models/buddyRequest');
const User = require('../models/user');

function computeAge(dob) {
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

function ensurePremium(req, res, next) {
  const hasPremium = true;
  if (!hasPremium) {
    return res.status(403).json({
      success: false,
      errorCode: 'PREMIUM_REQUIRED',
      message: 'Premium WL Coordination is required to search for buddies.'
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

router.post('/search', auth, requireVerifiedPnr(), ensurePremium, async (req, res, next) => {
  try {
    const { pnr } = req.body;
    if (!pnr) {
      throw new ApiError('INVALID_INPUT', 'PNR is required.', 400);
    }

    if (mongoose.connection.readyState !== 1) {
      throw new ApiError('DB_UNAVAILABLE', 'Database is unavailable', 503);
    }

    const phoneNumber = getPhoneNumber(req);
    const my = req.verifiedJourney;
    const j = my?.journey || {};
    if (!j.trainNumber || !j.class || !j.boardingDate) {
      throw new ApiError('JOURNEY_MISSING', 'Verified journey details missing. Please re-check PNR.', 400);
    }

    // Find confirmed co-passengers on the same train + date + class.
    const candidates = await VerifiedJourney.find({
      phoneNumber: { $ne: phoneNumber },
      'journey.trainNumber': j.trainNumber,
      'journey.class': j.class,
      'journey.boardingDate': j.boardingDate,
      statusType: 'CNF',
    })
      .sort({ verifiedAt: -1 })
      .limit(50)
      .lean();

    const phones = candidates.map((c) => c.phoneNumber).filter(Boolean);
    const users = await User.find({ phoneNumber: { $in: phones } })
      .select({ phoneNumber: 1, name: 1, dob: 1, age: 1 })
      .lean();
    const phoneToUser = new Map(users.map((u) => [u.phoneNumber, u]));

    const buddies = candidates.map((c) => {
      const u = phoneToUser.get(c.phoneNumber);
      const age = (u?.age !== undefined && u?.age !== null) ? u.age : computeAge(u?.dob);
      return {
        id: String(c._id),
        displayName: (u?.name && u.name.trim()) ? u.name.trim() : maskPhone(c.phoneNumber),
        age: (age !== undefined && age !== null) ? age : null,
        gender: 'N/A',
        languages: ['en'],
        from: (c.journey?.from || '').toString(),
        to: (c.journey?.to || '').toString(),
      };
    });

    return res.json({
      success: true,
      buddies,
    });
  } catch (err) {
    next(err);
  }
});

router.post('/request', auth, requireVerifiedPnr(), ensurePremium, async (req, res, next) => {
  try {
    const { pnr, buddyId, message } = req.body;
    if (!pnr || !buddyId) {
      throw new ApiError('INVALID_INPUT', 'PNR and buddyId are required.', 400);
    }

    if (mongoose.connection.readyState !== 1) {
      throw new ApiError('DB_UNAVAILABLE', 'Database is unavailable', 503);
    }

    const fromPhoneNumber = getPhoneNumber(req);
    const my = req.verifiedJourney;
    const j = my?.journey || {};

    const target = await VerifiedJourney.findById(buddyId).lean();
    if (!target) {
      throw new ApiError('BUDDY_NOT_FOUND', 'Buddy not found', 404);
    }
    if (target.phoneNumber === fromPhoneNumber) {
      throw new ApiError('INVALID_REQUEST', 'Cannot request yourself', 400);
    }
    if (target.statusType !== 'CNF') {
      throw new ApiError('BUDDY_NOT_CONFIRMED', 'Buddy is not confirmed', 400);
    }

    const tj = target.journey || {};
    const sameTrip =
      String(tj.trainNumber || '') === String(j.trainNumber || '') &&
      String(tj.class || '') === String(j.class || '') &&
      String(tj.boardingDate || '') === String(j.boardingDate || '');
    if (!sameTrip) {
      throw new ApiError('TRIP_MISMATCH', 'Buddy is not on your same train/class/date', 400);
    }

    const toPhoneNumber = target.phoneNumber;

    const doc = await BuddyRequest.findOneAndUpdate(
      { fromPhoneNumber, toPhoneNumber, pnr },
      {
        $setOnInsert: { fromPhoneNumber, toPhoneNumber, pnr },
        $set: {
          status: 'PENDING',
          message: message ? String(message).trim() : undefined,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    return res.json({
      success: true,
      request: {
        id: String(doc._id),
        status: doc.status,
      },
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
    const doc = await BuddyRequest.findById(requestId);
    if (!doc) {
      throw new ApiError('REQUEST_NOT_FOUND', 'Buddy request not found', 404);
    }

    const isReceiver = doc.toPhoneNumber === phoneNumber;
    const isSender = doc.fromPhoneNumber === phoneNumber;

    if ((status === 'ACCEPTED' || status === 'REJECTED') && !isReceiver) {
      throw new ApiError('FORBIDDEN', 'Only the receiver can accept/reject this request', 403);
    }
    if (status === 'CANCELLED' && !isSender) {
      throw new ApiError('FORBIDDEN', 'Only the sender can cancel this request', 403);
    }

    doc.status = status;
    await doc.save();

    return res.json({
      success: true,
      request: {
        id: String(doc._id),
        status: doc.status,
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/requests/incoming', auth, requireVerifiedPnr({ getPnr: (req) => req.query?.pnr }), ensurePremium, async (req, res, next) => {
  try {
    const phoneNumber = getPhoneNumber(req);
    const pnr = (req.query?.pnr || '').toString().trim();
    const items = await BuddyRequest.find({ toPhoneNumber: phoneNumber, pnr })
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
    const items = await BuddyRequest.find({ fromPhoneNumber: phoneNumber, pnr })
      .sort({ createdAt: -1 })
      .limit(200)
      .lean();

    res.json({ success: true, requests: items });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
