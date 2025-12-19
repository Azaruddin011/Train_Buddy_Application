const axios = require('axios');

class PnrService {
  constructor() {
    this.apiKey = process.env.PNR_API_KEY;
    this.apiBaseUrl = process.env.PNR_API_BASE_URL || 'https://indianrailapi.com/api/v2';
    this.apiProvider = process.env.PNR_API_PROVIDER || 'indianrail'; // 'indianrail' or 'rapidapi'
    this.rapidApiHost = process.env.RAPIDAPI_HOST || 'irctc1.p.rapidapi.com';
    this.cache = new Map();
    this.cacheTTL = 5 * 60 * 1000; // 5 minutes
  }

  async lookupPnr(pnr) {
    const cached = this.getFromCache(pnr);
    if (cached) {
      return cached;
    }

    try {
      const result = await this.fetchFromApi(pnr);
      this.saveToCache(pnr, result);
      return result;
    } catch (error) {
      console.error('PNR lookup failed:', error.message);
      throw this.handleApiError(error);
    }
  }

  async fetchFromApi(pnr) {
    if (!this.apiKey) {
      return this.getMockData(pnr);
    }

    if (this.apiProvider === 'rapidapi') {
      return this.fetchFromRapidApi(pnr);
    } else {
      return this.fetchFromIndianRailApi(pnr);
    }
  }

  async fetchFromIndianRailApi(pnr) {
    const response = await axios.get(`${this.apiBaseUrl}/pnr-check/pnr/${pnr}`, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`
      },
      timeout: 10000
    });

    return this.transformApiResponse(response.data, pnr);
  }

  async fetchFromRapidApi(pnr) {
    const baseUrl = (this.apiBaseUrl || '').replace(/\/$/, '');
    const endpoints = ['/api/v3/getPNRStatus', '/api/v1/getPNRStatus'];

    let lastError;
    for (const endpoint of endpoints) {
      try {
        const response = await axios.get(`${baseUrl}${endpoint}`, {
          params: { pnrNumber: pnr },
          headers: {
            'x-rapidapi-key': this.apiKey,
            'x-rapidapi-host': this.rapidApiHost
          },
          timeout: 10000
        });

        return this.transformRapidApiResponse(response.data, pnr);
      } catch (err) {
        lastError = err;
        const status = err?.response?.status;
        if (status && (status === 401 || status === 403 || status === 429 || status >= 500)) {
          throw err;
        }
      }
    }

    throw lastError;
  }

  transformApiResponse(apiData, pnr) {
    const trainInfo = apiData.data || {};
    const passengers = trainInfo.passenger || [];
    const firstPassenger = passengers[0] || {};

    const statusType = this.determineStatusType(firstPassenger.status);
    const positions = this.extractPositions(firstPassenger.status);

    return {
      success: true,
      pnr,
      journey: {
        trainNumber: trainInfo.train_number || 'N/A',
        trainName: trainInfo.train_name || 'N/A',
        class: trainInfo.class || 'N/A',
        from: trainInfo.from?.code || trainInfo.board?.code || 'N/A',
        to: trainInfo.to?.code || trainInfo.alight?.code || 'N/A',
        boardingDate: trainInfo.travel_date || trainInfo.doj || 'N/A'
      },
      status: {
        type: statusType,
        currentPosition: positions.current,
        originalPosition: positions.original
      },
      chart: {
        prepared: trainInfo.chart_prepared === 'CHART PREPARED',
        expectedTime: this.estimateChartTime(trainInfo.travel_date)
      },
      clarity: this.generateClarityMessage(statusType, positions.current)
    };
  }

  transformRapidApiResponse(apiData, pnr) {
    const data = apiData.data || apiData;
    const trainInfo = data.TrainDetails || {};
    const passengers = data.PassengerStatus || [];
    const firstPassenger = passengers[0] || {};

    const statusType = this.determineStatusType(firstPassenger.CurrentStatus || firstPassenger.BookingStatus);
    const positions = this.extractPositions(firstPassenger.CurrentStatus || firstPassenger.BookingStatus);

    return {
      success: true,
      pnr,
      journey: {
        trainNumber: trainInfo.TrainNo || trainInfo.trainNumber || 'N/A',
        trainName: trainInfo.TrainName || trainInfo.trainName || 'N/A',
        class: data.Class || trainInfo.Class || 'N/A',
        from: trainInfo.Source || trainInfo.from || 'N/A',
        to: trainInfo.Destination || trainInfo.to || 'N/A',
        boardingDate: data.DateOfJourney || trainInfo.doj || 'N/A'
      },
      status: {
        type: statusType,
        currentPosition: positions.current,
        originalPosition: positions.original
      },
      chart: {
        prepared: data.ChartPrepared === true || data.ChartStatus === 'CHART PREPARED',
        expectedTime: this.estimateChartTime(data.DateOfJourney || trainInfo.doj)
      },
      clarity: this.generateClarityMessage(statusType, positions.current)
    };
  }

  determineStatusType(statusString) {
    if (!statusString) return 'UNKNOWN';
    const upper = statusString.toUpperCase();
    if (upper.includes('CNF') || upper.includes('CONFIRM')) return 'CNF';
    if (upper.includes('RAC')) return 'RAC';
    if (upper.includes('W/L') || upper.includes('WL')) return 'WL';
    return 'UNKNOWN';
  }

  extractPositions(statusString) {
    if (!statusString) return { current: 0, original: 0 };
    
    const match = statusString.match(/(\d+)/g);
    if (!match || match.length === 0) {
      return { current: 0, original: 0 };
    }
    
    const current = parseInt(match[0], 10);
    const original = match.length > 1 ? parseInt(match[1], 10) : current;
    
    return { current, original };
  }

  estimateChartTime(travelDate) {
    if (!travelDate) return new Date().toISOString();
    
    try {
      const parts = travelDate.split('-');
      let date;
      
      if (parts.length === 3) {
        const day = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10) - 1;
        const year = parseInt(parts[2], 10);
        date = new Date(year, month, day);
      } else {
        date = new Date(travelDate);
      }
      
      date.setHours(date.getHours() - 4);
      return date.toISOString();
    } catch (e) {
      return new Date().toISOString();
    }
  }

  generateClarityMessage(statusType, position) {
    const messages = {
      'WL': {
        title: 'What this means for you',
        body: `Your ticket is currently on the waiting list at position ${position}. Final status will be known after chart preparation, typically 4 hours before departure.`,
        tips: [
          'Final status will be known after chart preparation.',
          `WL below ${position + 10} on this route often moves to RAC or CNF, but not guaranteed.`,
          'Keep checking status regularly as it may change.'
        ]
      },
      'RAC': {
        title: 'RAC Status Explained',
        body: `You have a RAC (Reservation Against Cancellation) ticket at position ${position}. You are guaranteed travel but may share a berth initially.`,
        tips: [
          'RAC passengers get confirmed berths if cancellations happen.',
          'You can board the train with RAC status.',
          'Check after chart preparation for potential upgrades.'
        ]
      },
      'CNF': {
        title: 'Confirmed Ticket',
        body: 'Your ticket is confirmed. You have a reserved seat/berth for your journey.',
        tips: [
          'Carry a valid ID proof for verification.',
          'Reach the station at least 30 minutes before departure.',
          'Check your coach and berth number on the chart.'
        ]
      },
      'UNKNOWN': {
        title: 'Status Information',
        body: 'Unable to determine exact status. Please check the official IRCTC website or contact railway helpline.',
        tips: [
          'Verify your PNR number is correct.',
          'Try checking again after some time.',
          'Contact railway customer care if issue persists.'
        ]
      }
    };

    return messages[statusType] || messages['UNKNOWN'];
  }

  getMockData(pnr) {
    return {
      success: true,
      pnr,
      journey: {
        trainNumber: '12951',
        trainName: 'Mumbai Rajdhani',
        class: '3A',
        from: 'BCT',
        to: 'NDLS',
        boardingDate: '2025-12-20'
      },
      status: {
        type: 'WL',
        currentPosition: 12,
        originalPosition: 25
      },
      chart: {
        prepared: false,
        expectedTime: '2025-12-20T15:00:00+05:30'
      },
      clarity: {
        title: 'What this means for you',
        body: 'Your ticket is currently WL 12. Final status will be known after chart preparation...',
        tips: [
          'Final status will be known after chart preparation.',
          'WL below 15 on this route often moves to RAC or CNF, but not guaranteed.'
        ]
      }
    };
  }

  getFromCache(pnr) {
    const cached = this.cache.get(pnr);
    if (!cached) return null;
    
    const age = Date.now() - cached.timestamp;
    if (age > this.cacheTTL) {
      this.cache.delete(pnr);
      return null;
    }
    
    return cached.data;
  }

  saveToCache(pnr, data) {
    this.cache.set(pnr, {
      data,
      timestamp: Date.now()
    });
    
    if (this.cache.size > 1000) {
      const oldestKey = this.cache.keys().next().value;
      this.cache.delete(oldestKey);
    }
  }

  handleApiError(error) {
    if (error.response) {
      const status = error.response.status;
      if (status === 404) {
        return new Error('PNR not found or invalid');
      } else if (status === 429) {
        return new Error('Too many requests. Please try again later');
      } else if (status >= 500) {
        return new Error('Railway server unavailable. Please try again');
      }
    } else if (error.code === 'ECONNABORTED') {
      return new Error('Request timeout. Please try again');
    }
    
    return new Error('Unable to fetch PNR status. Please try again');
  }
}

module.exports = new PnrService();
