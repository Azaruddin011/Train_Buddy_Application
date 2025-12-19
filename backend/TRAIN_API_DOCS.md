# TrainBuddy Train API Documentation

This document covers all train-related API endpoints available in TrainBuddy backend.

## Authentication

All endpoints require authentication via Bearer token:

```
Authorization: Bearer YOUR_JWT_TOKEN
```

For development, you can use `MOCK_JWT_TOKEN`.

## Base URL

```
http://localhost:4000
```

## Implementation Status

| Endpoint | Status | Data Source |
|----------|--------|-------------|
| Station Search | ✅ Working | Real RapidAPI Data with Mock Fallback |
| Train Schedule | ✅ Working | Real RapidAPI Data with Mock Fallback |
| Train Search | ✅ Working | Real RapidAPI Data with Mock Fallback |
| Live Train Status | ✅ Working | Real RapidAPI Data with Mock Fallback |
| Seat Availability | ✅ Working | Real RapidAPI Data with Mock Fallback |
| Fare Enquiry | ✅ Working | Real RapidAPI Data with Mock Fallback |
| Live Station | ✅ Working | Real RapidAPI Data with Mock Fallback |

> **Note:** All endpoints now attempt to fetch real data from RapidAPI first. If the API call fails (due to rate limits, endpoint unavailability, etc.), they automatically fall back to realistic mock data. This ensures the API is always responsive while prioritizing real data when available.

## Train Search

### Search Trains Between Stations

```
POST /trains/search
```

**Request Body:**
```json
{
  "fromStation": "NDLS",
  "toStation": "BCT",
  "date": "2025-12-25"
}
```

**Response:**
```json
{
  "success": true,
  "trains": [
    {
      "trainNumber": "12951",
      "trainName": "Mumbai Rajdhani",
      "fromStation": "NDLS",
      "toStation": "BCT",
      "departureTime": "16:25",
      "arrivalTime": "08:15",
      "duration": "15h 50m",
      "distance": "1384 km",
      "classes": ["1A", "2A", "3A"],
      "days": [
        {"day": "Mon", "runs": true},
        {"day": "Tue", "runs": true},
        // ...
      ]
    },
    // More trains...
  ]
}
```

## Train Schedule

### Get Train Schedule

```
GET /trains/schedule/:trainNumber
```

**Example:** `/trains/schedule/12951`

**Response:**
```json
{
  "success": true,
  "trainNumber": "12951",
  "trainName": "Mumbai Rajdhani",
  "schedule": [
    {
      "stationCode": "NDLS",
      "stationName": "New Delhi",
      "arrivalTime": "16:15",
      "departureTime": "16:25",
      "distance": "0 km",
      "day": 1,
      "haltTime": "10 min"
    },
    // More stations...
  ]
}
```

## Live Train Status

### Get Live Train Status

```
POST /trains/live-status
```

**Request Body:**
```json
{
  "trainNumber": "12951",
  "date": "2025-12-25"
}
```

**Response:**
```json
{
  "success": true,
  "trainNumber": "12951",
  "trainName": "Mumbai Rajdhani",
  "currentStation": "BRC",
  "currentStationName": "Vadodara Jn",
  "lastUpdated": "2025-12-25 23:45",
  "expectedArrival": "2025-12-26 08:30",
  "delay": "15 min",
  "status": "Running"
}
```

**Example Call:**
```bash
curl -X POST "http://localhost:4000/trains/live-status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer MOCK_JWT_TOKEN" \
  -d '{"trainNumber":"12951","date":"2025-12-25"}'
```

## Station Search

### Search Stations

```
GET /trains/stations?query=:query
```

**Example:** `/trains/stations?query=del`

**Response:**
```json
{
  "success": true,
  "stations": [
    {
      "code": "NDLS",
      "name": "NEW DELHI",
      "state": "DELHI"
    },
    {
      "code": "DLI",
      "name": "OLD DELHI",
      "state": "DELHI"
    },
    {
      "code": "DEE",
      "name": "DELHI SARAI ROHILLA",
      "state": "DELHI"
    },
    {
      "code": "DEC",
      "name": "DELHI CANTT",
      "state": "DELHI"
    },
    {
      "code": "DSA",
      "name": "DELHI SHAHDARA",
      "state": "DELHI"
    }
    // More stations...
  ]
}
```

**Example Call:**
```bash
curl -X GET "http://localhost:4000/trains/stations?query=del" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer MOCK_JWT_TOKEN"
```

## Seat Availability

### Check Seat Availability

```
POST /trains/availability
```

**Request Body:**
```json
{
  "trainNumber": "12951",
  "fromStation": "NDLS",
  "toStation": "BCT",
  "date": "2025-12-25",
  "travelClass": "3A",
  "quota": "GN"
}
```

**Response:**
```json
{
  "success": true,
  "trainNumber": "12951",
  "trainName": "Mumbai Rajdhani",
  "fromStation": "NDLS",
  "toStation": "BCT",
  "class": "3A",
  "quota": "GN",
  "availability": [
    {
      "date": "2025-12-25",
      "status": "AVAILABLE 3"
    }
  ],
  "fare": "₹1200"
}
```

**Example Call:**
```bash
curl -X POST "http://localhost:4000/trains/availability" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer MOCK_JWT_TOKEN" \
  -d '{"trainNumber":"12951","fromStation":"NDLS","toStation":"BCT","date":"2025-12-25","travelClass":"3A","quota":"GN"}'
```

## Fare Enquiry

### Get Train Fare

```
POST /trains/fare
```

**Request Body:**
```json
{
  "trainNumber": "12951",
  "fromStation": "NDLS",
  "toStation": "BCT",
  "travelClass": "3A",
  "quota": "GN"
}
```

**Response:**
```json
{
  "success": true,
  "trainNumber": "12951",
  "trainName": "Mumbai Rajdhani",
  "fromStation": "NDLS",
  "toStation": "BCT",
  "class": "3A",
  "quota": "GN",
  "fare": "₹1375",
  "breakup": {
    "baseFare": "₹1200",
    "reservationCharge": "₹40",
    "superFastCharge": "₹75",
    "gst": "₹60",
    "total": "₹1375"
  }
}
```

**Example Call:**
```bash
curl -X POST "http://localhost:4000/trains/fare" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer MOCK_JWT_TOKEN" \
  -d '{"trainNumber":"12951","fromStation":"NDLS","toStation":"BCT","travelClass":"3A","quota":"GN"}'
```

## Live Station

### Get Live Station

```
GET /trains/live-station/:stationCode?hours=:hours
```

**Example:** `/trains/live-station/NDLS?hours=2`

**Response:**
```json
{
  "success": true,
  "stationCode": "NDLS",
  "stationName": "New Delhi",
  "trains": [
    {
      "trainNumber": "12951",
      "trainName": "Mumbai Rajdhani",
      "scheduledArrival": "16:15",
      "scheduledDeparture": "16:25",
      "expectedArrival": "16:15",
      "expectedDeparture": "16:25",
      "delay": "0 min",
      "platform": "5"
    },
    // More trains...
  ]
}
```

## Error Handling

All endpoints return standardized error responses:

```json
{
  "success": false,
  "errorCode": "ERROR_CODE",
  "message": "Human-readable error message"
}
```

Common error codes:
- `INVALID_PARAMETERS`: Missing or invalid request parameters
- `TRAIN_SEARCH_FAILED`: Failed to search trains
- `TRAIN_SCHEDULE_FAILED`: Failed to fetch train schedule
- `LIVE_STATUS_FAILED`: Failed to fetch live train status
- `STATION_SEARCH_FAILED`: Failed to search stations
- `SEAT_AVAILABILITY_FAILED`: Failed to check seat availability
- `FARE_LOOKUP_FAILED`: Failed to fetch fare
- `LIVE_STATION_FAILED`: Failed to fetch live station data

## Rate Limits

The RapidAPI provider may impose rate limits. The backend implements caching to reduce API calls:
- Results are cached for 5 minutes
- Identical requests within this period return cached results
- Cache is automatically cleared if it grows too large

## Implementation Notes

- All endpoints use the RapidAPI IRCTC API
- Responses are normalized to a consistent format
- Multiple API versions are supported with fallbacks
- Error handling includes user-friendly messages
