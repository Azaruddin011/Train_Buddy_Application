const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pnrService = require('../services/pnrService');
const mongoose = require('mongoose');
const VerifiedJourney = require('../models/verifiedJourney');

router.post('/lookup', auth, async (req, res) => {
  const { pnr } = req.body;

  if (!pnr || typeof pnr !== 'string' || pnr.length !== 10) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PNR',
      message: 'Enter a valid 10-digit PNR.'
    });
  }

  try {
    const result = await pnrService.lookupPnr(pnr);

    try {
      const phoneNumber = (req.user?.phoneNumber || req.user?.phone || '').toString().trim();
      if (result?.success && phoneNumber && mongoose.connection.readyState === 1) {
        await VerifiedJourney.updateOne(
          { phoneNumber, pnr },
          {
            $set: {
              phoneNumber,
              pnr,
              journey: result.journey || {},
              statusType: result.status?.type || null,
              verifiedAt: new Date(),
            },
          },
          { upsert: true }
        );
      }
    } catch (err) {
      // Best-effort persistence. Don't block PNR lookup on DB write failures.
      console.warn('Failed to persist verified journey:', err?.message || err);
    }

    return res.json(result);
  } catch (error) {
    console.error('PNR lookup error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'PNR_LOOKUP_FAILED',
      message: error.message || 'Unable to fetch PNR status. Please try again.'
    });
  }
});

module.exports = router;
