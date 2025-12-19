const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pnrService = require('../services/pnrService');

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
