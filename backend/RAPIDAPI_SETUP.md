# RapidAPI Setup Guide for TrainBuddy

## What You Found

You discovered the **IRCTC API on RapidAPI** - this is a great option for getting real PNR data!

## Step-by-Step Setup

### 1. Subscribe to the API

On the RapidAPI page you're viewing:

1. Click **"Subscribe to Test"** or **"Pricing"** button
2. Choose a plan:
   - **Basic (Free)**: Usually 100-500 requests/month
   - **Pro**: More requests, better rate limits
   - **Ultra/Mega**: For production scale

3. Complete the subscription

### 2. Get Your API Key

After subscribing:

1. Look for **"X-RapidAPI-Key"** in the code snippets section
2. It will look like: `x-rapidapi-key: 'abc123def456...'`
3. Copy this key

### 3. Configure Your Backend

Create a `.env` file in the `backend/` folder:

```bash
cd backend
cp .env.example .env
```

Edit `.env` and add:

```env
PORT=4000

# RapidAPI Configuration
PNR_API_PROVIDER=rapidapi
PNR_API_KEY=your_rapidapi_key_here
PNR_API_BASE_URL=https://irctc1.p.rapidapi.com
RAPIDAPI_HOST=irctc1.p.rapidapi.com
```

**Replace `your_rapidapi_key_here` with the actual key from RapidAPI!**

### 4. Install Dependencies & Start

```bash
npm install
npm start
```

You should see:
```
TrainBuddy backend listening on port 4000
```

### 5. Test It

```bash
curl -X POST http://localhost:4000/pnr/lookup \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer MOCK_JWT_TOKEN' \
  -d '{"pnr":"1234567890"}'
```

Replace `1234567890` with a real PNR number to test with live data.

## What the Code Does

The backend now automatically:

✅ **Detects RapidAPI** when `PNR_API_PROVIDER=rapidapi`  
✅ **Uses correct headers** (`x-rapidapi-key`, `x-rapidapi-host`)  
✅ **Transforms RapidAPI response** to TrainBuddy format  
✅ **Caches results** for 5 minutes  
✅ **Handles errors** gracefully  

## Required RapidAPI Query Param

RapidAPI's PNR endpoint requires the query param:

- **`pnrNumber`** (String)

You do not need to set this manually.

- Your Flutter app sends `pnr` to your backend (`POST /pnr/lookup`).
- The backend automatically forwards it to RapidAPI as `pnrNumber`.

## RapidAPI Response Format

RapidAPI typically returns:

```json
{
  "data": {
    "Pnr": "1234567890",
    "TrainDetails": {
      "TrainNo": "12951",
      "TrainName": "Mumbai Rajdhani",
      "Source": "BCT",
      "Destination": "NDLS"
    },
    "PassengerStatus": [
      {
        "BookingStatus": "WL 25",
        "CurrentStatus": "WL 12"
      }
    ],
    "DateOfJourney": "2025-12-20",
    "Class": "3A",
    "ChartPrepared": false
  }
}
```

The service transforms this into TrainBuddy's format automatically.

## Checking Your API Usage

1. Go to your RapidAPI dashboard
2. Click on **"My Apps"** or **"Analytics"**
3. View your API call count and remaining quota

## Cost Optimization

With the built-in caching:
- Same PNR checked within 5 minutes = **no API call** (cached)
- Different PNRs = **new API call**
- Estimated savings: **60-70%** if users check multiple times

## Troubleshooting

### "Invalid API Key"
- Check your `.env` file has the correct key
- Make sure you copied the full key from RapidAPI
- Verify you're subscribed to the API

### "Rate Limit Exceeded"
- You've hit your plan's request limit
- Wait for the limit to reset (usually monthly)
- Upgrade to a higher plan

### "PNR Not Found"
- The PNR might be invalid or expired
- Try with a different PNR
- Check on official IRCTC website first

### Still Getting Mock Data
- Verify `.env` file exists in `backend/` folder
- Check `PNR_API_PROVIDER=rapidapi` is set
- Restart the server after changing `.env`
- Check for typos in environment variable names

## Alternative: IndianRailAPI

If RapidAPI doesn't work out, you can switch to IndianRailAPI:

```env
PNR_API_PROVIDER=indianrail
PNR_API_KEY=your_indianrail_key
PNR_API_BASE_URL=https://indianrailapi.com/api/v2
```

The code supports both providers!

## Next Steps

1. ✅ Subscribe to RapidAPI IRCTC API
2. ✅ Get your API key
3. ✅ Add it to `.env`
4. ✅ Test with real PNR
5. 🚀 Deploy to production

## Support

- **RapidAPI Issues**: Use RapidAPI support/dashboard
- **Integration Issues**: Check the logs in your terminal
- **API Format Changes**: Update `transformRapidApiResponse()` in `pnrService.js`
