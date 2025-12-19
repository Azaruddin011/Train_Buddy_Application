/**
 * Custom API Error class for standardized error handling
 */
class ApiError extends Error {
  /**
   * Create a new API error
   * @param {string} code - Error code
   * @param {string} message - Error message
   * @param {number} statusCode - HTTP status code
   */
  constructor(code, message, statusCode = 500) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.statusCode = statusCode;
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * Convert to JSON response format
   * @returns {Object} - Formatted error response
   */
  toJSON() {
    return {
      success: false,
      errorCode: this.code,
      message: this.message
    };
  }
}

module.exports = ApiError;
