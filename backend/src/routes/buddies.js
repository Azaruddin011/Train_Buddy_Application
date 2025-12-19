const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

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

router.post('/search', auth, ensurePremium, (req, res) => {
  const { pnr } = req.body;
  if (!pnr) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_INPUT',
      message: 'PNR is required.'
    });
  }

  const buddies = [
    {
      id: 'buddy_101',
      displayName: 'Passenger A',
      ageGroup: '26_35',
      gender: 'M',
      languages: ['hi', 'en'],
      from: 'BCT',
      to: 'NDLS'
    }
  ];

  return res.json({
    success: true,
    buddies
  });
});

router.post('/request', auth, ensurePremium, (req, res) => {
  const { pnr, buddyId } = req.body;
  if (!pnr || !buddyId) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_INPUT',
      message: 'PNR and buddyId are required.'
    });
  }

  return res.json({
    success: true,
    request: {
      id: 'req_555',
      status: 'PENDING'
    }
  });
});

router.post('/respond', auth, (req, res) => {
  const { requestId, action } = req.body;
  if (!requestId || !action) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_INPUT',
      message: 'requestId and action are required.'
    });
  }

  return res.json({
    success: true,
    request: {
      id: requestId,
      status: action === 'ACCEPT' ? 'ACCEPTED' : 'IGNORED'
    }
  });
});

module.exports = router;
