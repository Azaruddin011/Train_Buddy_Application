# PNR Status Integration Guide

## Overview

TrainBuddy now supports real-time PNR (Passenger Name Record) status lookup from Indian Railways through third-party API providers.

## How It Works

The backend includes a `PnrService` that:
1. **Fetches real PNR data** from third-party APIs (when API key is configured)
2. **Falls back to mock data** for development (when no API key is set)
3. **Caches responses** for 5 minutes to reduce API costs
4. **Transforms API responses** into TrainBuddy's standardized format
5. **Handles errors gracefully** with user-friendly messages

## Setup Options

### Option 1: Use Mock Data (Development)
**No setup required!** The service automatically returns mock data when `PNR_API_KEY` is not set.

```bash
# Just start the server
npm start
```

### Option 2: Integrate Real PNR API (Production)

#### Step 1: Choose a Provider

**Recommended: IndianRailAPI.com**
- Website: https://indianrailapi.com
- Features: PNR status, train info, seat availability, live status
- Pricing: Freemium (check their pricing page)
- Reliability: Good uptime, documented API

**Alternative: RapidAPI Marketplace**
- Search "IRCTC PNR" on https://rapidapi.com
- Multiple providers available
- Pay-per-call pricing
- Easy integration

#### Step 2: Get API Key

1. Sign up at your chosen provider
2. Subscribe to their PNR API plan
3. Copy your API key

#### Step 3: Configure Backend

Create a `.env` file in the `backend/` folder:

```bash
# Copy the example file
cp .env.example .env
```

Edit `.env` and add your API key:

```env
PORT=4000
PNR_API_KEY=your_actual_api_key_here
PNR_API_BASE_URL=https://indianrailapi.com/api/v2
```

#### Step 4: Install Dependencies & Restart

```bash
npm install
npm start
```

## API Response Format

The service transforms various API formats into this standardized structure:

```json
{
  "success": true,
  "pnr": "1234567890",
  "journey": {
    "trainNumber": "12951",
    "trainName": "Mumbai Rajdhani",
    "class": "3A",
    "from": "BCT",
    "to": "NDLS",
    "boardingDate": "2025-12-20"
  },
  "status": {
    "type": "WL",
    "currentPosition": 12,
    "originalPosition": 25
  },
  "chart": {
    "prepared": false,
    "expectedTime": "2025-12-20T15:00:00+05:30"
  },
  "clarity": {
    "title": "What this means for you",
    "body": "Your ticket is currently WL 12...",
    "tips": [
      "Final status will be known after chart preparation.",
      "WL below 15 often moves to RAC or CNF, but not guaranteed."
    ]
  }
}
```

## Features

### ✅ Smart Caching
- Responses cached for 5 minutes
- Reduces API costs
- Improves response time
- Automatic cache cleanup (max 1000 entries)

### ✅ Status Type Detection
Automatically detects:
- **CNF** (Confirmed)
- **RAC** (Reservation Against Cancellation)
- **WL** (Waiting List)
- **UNKNOWN** (fallback)

### ✅ Position Extraction
Parses status strings like:
- `"W/L 12,RLGN"` → current: 12
- `"RAC 5"` → current: 5
- `"CNF/S3/45"` → confirmed

### ✅ User-Friendly Messages
Generates context-aware clarity messages based on:
- Status type (WL/RAC/CNF)
- Current position
- Route patterns

### ✅ Error Handling
Handles:
- Invalid PNR (404)
- Rate limiting (429)
- Server errors (500+)
- Timeouts (10s)
- Network failures

## Testing

### Test with Mock Data
```bash
curl -X POST http://localhost:4000/pnr/lookup \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer MOCK_JWT_TOKEN' \
  -d '{"pnr":"1234567890"}'
```

### Test with Real API
1. Set `PNR_API_KEY` in `.env`
2. Use a real PNR number
3. Check response format matches

## Cost Optimization Tips

1. **Cache aggressively** (already implemented)
2. **Rate limit users** (add middleware)
3. **Monitor usage** (add logging)
4. **Set daily limits** (add quota tracking)
5. **Use webhooks** if provider supports (for chart updates)

## Switching Providers

The service is designed to be provider-agnostic. To switch:

1. Update `PNR_API_BASE_URL` in `.env`
2. Modify `fetchFromApi()` method in `pnrService.js` if endpoint structure differs
3. Update `transformApiResponse()` if response format differs

## Troubleshooting

### "PNR not found"
- PNR may be invalid or flushed
- Check if PNR is 10 digits
- Try on official IRCTC website first

### "Too many requests"
- API rate limit hit
- Wait and retry
- Consider upgrading API plan

### "Railway server unavailable"
- Indian Railways backend down
- Temporary issue
- Retry after some time

### Mock data always returned
- Check if `PNR_API_KEY` is set in `.env`
- Verify `.env` file is in `backend/` folder
- Restart server after adding key

## Security Notes

- **Never commit `.env`** to git (already in `.gitignore`)
- **Rotate API keys** regularly
- **Monitor for abuse** (add rate limiting)
- **Validate PNR format** before API call (already done)
- **Don't log sensitive data** (PNRs are PII)

## Future Enhancements

- [ ] Database caching (longer TTL)
- [ ] Webhook support for chart updates
- [ ] Batch PNR lookup
- [ ] Historical status tracking
- [ ] Push notifications on status change
- [ ] Fallback to multiple providers

## Support

For API-specific issues:
- IndianRailAPI: Check their docs/support
- RapidAPI: Use their dashboard support

For TrainBuddy integration issues:
- Check logs: `console.error` in `pnrService.js`
- Verify `.env` configuration
- Test with mock data first
