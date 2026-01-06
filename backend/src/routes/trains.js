const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const trainService = require('../services/trainService');

/**
 * Search trains between stations
 * POST /trains/search
 * Body: { fromStation, toStation, date }
 */
router.post('/search', auth, async (req, res) => {
  const { fromStation, toStation, date } = req.body;

  if (!fromStation || !toStation || !date) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Missing required parameters: fromStation, toStation, date'
    });
  }

  try {
    const result = await trainService.searchTrains(fromStation, toStation, date);
    return res.json(result);
  } catch (error) {
    console.error('Train search error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'TRAIN_SEARCH_FAILED',
      message: error.message || 'Unable to search trains. Please try again.'
    });
  }
});

/**
 * Get train schedule
 * GET /trains/schedule/:trainNumber
 */
router.get('/schedule/:trainNumber', auth, async (req, res) => {
  const { trainNumber } = req.params;

  if (!trainNumber) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Train number is required'
    });
  }

  try {
    const result = await trainService.getTrainSchedule(trainNumber);
    return res.json(result);
  } catch (error) {
    console.error('Train schedule error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'TRAIN_SCHEDULE_FAILED',
      message: error.message || 'Unable to fetch train schedule. Please try again.'
    });
  }
});

/**
 * Get live train status
 * POST /trains/live-status
 * Body: { trainNumber, date }
 */
router.post('/live-status', auth, async (req, res) => {
  const { trainNumber, date } = req.body;

  if (!trainNumber || !date) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Missing required parameters: trainNumber, date'
    });
  }

  try {
    const result = await trainService.getLiveStatus(trainNumber, date);
    return res.json(result);
  } catch (error) {
    console.error('Live status error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'LIVE_STATUS_FAILED',
      message: error.message || 'Unable to fetch live status. Please try again.'
    });
  }
});

/**
 * Search stations
 * GET /trains/stations?query=:query
 */
router.get('/stations', async (req, res) => {
  const { query } = req.query;

  if (!query || query.length < 2) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Query must be at least 2 characters'
    });
  }

  try {
    const result = await trainService.searchStations(query);
    return res.json(result);
  } catch (error) {
    console.error('Station search error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'STATION_SEARCH_FAILED',
      message: error.message || 'Unable to search stations. Please try again.'
    });
  }
});

/**
 * Check seat availability
 * POST /trains/availability
 * Body: { trainNumber, fromStation, toStation, date, travelClass, quota }
 */
router.post('/availability', auth, async (req, res) => {
  const { trainNumber, fromStation, toStation, date, travelClass, quota = "GN" } = req.body;

  if (!trainNumber || !fromStation || !toStation || !date || !travelClass) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Missing required parameters: trainNumber, fromStation, toStation, date, travelClass'
    });
  }

  try {
    const result = await trainService.checkSeatAvailability(
      trainNumber, fromStation, toStation, date, travelClass, quota
    );
    return res.json(result);
  } catch (error) {
    console.error('Seat availability error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'SEAT_AVAILABILITY_FAILED',
      message: error.message || 'Unable to check seat availability. Please try again.'
    });
  }
});

/**
 * Get fare
 * POST /trains/fare
 * Body: { trainNumber, fromStation, toStation, travelClass, quota }
 */
router.post('/fare', auth, async (req, res) => {
  const { trainNumber, fromStation, toStation, travelClass, quota = "GN" } = req.body;

  if (!trainNumber || !fromStation || !toStation || !travelClass) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Missing required parameters: trainNumber, fromStation, toStation, travelClass'
    });
  }

  try {
    const result = await trainService.getFare(
      trainNumber, fromStation, toStation, travelClass, quota
    );
    return res.json(result);
  } catch (error) {
    console.error('Fare lookup error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'FARE_LOOKUP_FAILED',
      message: error.message || 'Unable to fetch fare. Please try again.'
    });
  }
});

/**
 * Get live station
 * GET /trains/live-station/:stationCode?hours=:hours
 */
router.get('/live-station/:stationCode', auth, async (req, res) => {
  const { stationCode } = req.params;
  const hours = parseInt(req.query.hours) || 2;

  if (!stationCode) {
    return res.status(400).json({
      success: false,
      errorCode: 'INVALID_PARAMETERS',
      message: 'Station code is required'
    });
  }

  try {
    const result = await trainService.getLiveStation(stationCode, hours);
    return res.json(result);
  } catch (error) {
    console.error('Live station error:', error);
    return res.status(500).json({
      success: false,
      errorCode: 'LIVE_STATION_FAILED',
      message: error.message || 'Unable to fetch live station data. Please try again.'
    });
  }
});

module.exports = router;
