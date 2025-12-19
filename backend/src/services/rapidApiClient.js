/**
 * RapidAPI IRCTC Client
 * Base client for all RapidAPI IRCTC endpoints
 */
const axios = require('axios');

class RapidApiClient {
  constructor() {
    this.apiKey = process.env.PNR_API_KEY;
    this.baseUrl = process.env.PNR_API_BASE_URL || 'https://irctc1.p.rapidapi.com';
    this.host = process.env.RAPIDAPI_HOST || 'irctc1.p.rapidapi.com';
    this.cache = new Map();
    this.cacheTTL = 5 * 60 * 1000; // 5 minutes
  }

  /**
   * Make a GET request to any RapidAPI endpoint
   * @param {string} endpoint - API endpoint path (e.g., '/api/v3/getPNRStatus')
   * @param {Object} params - Query parameters
   * @param {boolean} useCache - Whether to use cache (default: true)
   * @returns {Promise<Object>} - API response data
   */
  async get(endpoint, params = {}, useCache = true) {
    const cacheKey = this.getCacheKey(endpoint, params);
    
    if (useCache) {
      const cached = this.getFromCache(cacheKey);
      if (cached) return cached;
    }

    try {
      // For development only - ignore SSL certificate errors
      const httpsAgent = new (require('https').Agent)({ rejectUnauthorized: false });
      
      const response = await axios.get(`${this.baseUrl}${endpoint}`, {
        params,
        headers: {
          'x-rapidapi-key': this.apiKey,
          'x-rapidapi-host': this.host
        },
        timeout: 10000,
        httpsAgent // Add this to bypass certificate validation
      });

      const result = response.data;
      
      if (useCache) {
        this.saveToCache(cacheKey, result);
      }
      
      return result;
    } catch (error) {
      console.error(`RapidAPI error (${endpoint}):`, error.message);
      throw this.handleApiError(error);
    }
  }

  /**
   * Generate a cache key from endpoint and params
   * @private
   */
  getCacheKey(endpoint, params) {
    return `${endpoint}:${JSON.stringify(params)}`;
  }

  /**
   * Get item from cache if not expired
   * @private
   */
  getFromCache(key) {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    const age = Date.now() - cached.timestamp;
    if (age > this.cacheTTL) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }

  /**
   * Save item to cache with timestamp
   * @private
   */
  saveToCache(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    });
    
    // Cleanup if cache gets too large
    if (this.cache.size > 1000) {
      const oldestKey = this.cache.keys().next().value;
      this.cache.delete(oldestKey);
    }
  }

  /**
   * Handle API errors with user-friendly messages
   * @private
   */
  handleApiError(error) {
    if (error.response) {
      const status = error.response.status;
      if (status === 404) {
        return new Error('Resource not found');
      } else if (status === 429) {
        return new Error('API rate limit exceeded. Please try again later');
      } else if (status === 401 || status === 403) {
        return new Error('API authentication failed. Check your API key');
      } else if (status >= 500) {
        return new Error('Railway server unavailable. Please try again');
      }
    } else if (error.code === 'ECONNABORTED') {
      return new Error('Request timeout. Please try again');
    }
    
    return new Error('Unable to fetch data. Please try again');
  }
}

module.exports = new RapidApiClient();
