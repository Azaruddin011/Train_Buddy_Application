import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'connectivity_service.dart';

class ApiClient {
  final String baseUrl;
  final String? Function() tokenProvider;
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Retry configuration
  final int maxRetries = 3;
  final Duration initialRetryDelay = const Duration(seconds: 1);
  
  // Cache for offline mode
  final Map<String, CachedResponse> _responseCache = {};

  ApiClient({required this.baseUrl, required this.tokenProvider});

  /// Post request with offline handling and retry mechanism
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool useCache = false,
    Duration cacheTtl = const Duration(minutes: 5),
  }) async {
    // Check connectivity first
    if (!_connectivityService.isOnline) {
      // If we have a cached response and caching is enabled, return it
      if (useCache) {
        final cacheKey = _getCacheKey('POST', path, body);
        final cachedData = _responseCache[cacheKey];
        if (cachedData != null && !cachedData.isExpired()) {
          return cachedData.data;
        }
      }
      
      // Otherwise, throw offline error
      throw ApiException(
        'No internet connection', 
        ApiErrorType.offline,
        retryable: true,
      );
    }
    
    // Prepare headers
    final token = tokenProvider();
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    // Attempt request with retries
    return _executeWithRetry(() async {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: requestHeaders,
        body: jsonEncode(body),
      );
      
      final responseData = _handleResponse(response);
      
      // Cache the successful response if caching is enabled
      if (useCache) {
        final cacheKey = _getCacheKey('POST', path, body);
        _responseCache[cacheKey] = CachedResponse(
          data: responseData,
          timestamp: DateTime.now(),
          ttl: cacheTtl,
        );
      }
      
      return responseData;
    });
  }

  /// Get request with offline handling and retry mechanism
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    bool useCache = true,
    Duration cacheTtl = const Duration(minutes: 5),
  }) async {
    // Check connectivity first
    if (!_connectivityService.isOnline) {
      // If we have a cached response and caching is enabled, return it
      if (useCache) {
        final cacheKey = _getCacheKey('GET', path);
        final cachedData = _responseCache[cacheKey];
        if (cachedData != null && !cachedData.isExpired()) {
          return cachedData.data;
        }
      }
      
      // Otherwise, throw offline error
      throw ApiException(
        'No internet connection', 
        ApiErrorType.offline,
        retryable: true,
      );
    }
    
    // Prepare headers
    final token = tokenProvider();
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    // Attempt request with retries
    return _executeWithRetry(() async {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: requestHeaders,
      );
      
      final responseData = _handleResponse(response);
      
      // Cache the successful response if caching is enabled
      if (useCache) {
        final cacheKey = _getCacheKey('GET', path);
        _responseCache[cacheKey] = CachedResponse(
          data: responseData,
          timestamp: DateTime.now(),
          ttl: cacheTtl,
        );
      }
      
      return responseData;
    });
  }
  
  /// Execute a request with exponential backoff retry
  Future<Map<String, dynamic>> _executeWithRetry(Future<Map<String, dynamic>> Function() requestFn) async {
    int attempts = 0;
    Duration delay = initialRetryDelay;
    
    while (true) {
      try {
        attempts++;
        return await requestFn();
      } catch (e) {
        // If we've reached max retries or the error isn't retryable, rethrow
        if (attempts >= maxRetries || 
            (e is ApiException && !e.retryable)) {
          rethrow;
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }
  
  /// Handle API response and convert to appropriate format or throw exception
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException(
          'Invalid response format', 
          ApiErrorType.parseError,
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode == 401) {
      throw ApiException(
        'Unauthorized access', 
        ApiErrorType.unauthorized,
        statusCode: response.statusCode,
        retryable: false,
      );
    } else if (response.statusCode == 404) {
      throw ApiException(
        'Resource not found', 
        ApiErrorType.notFound,
        statusCode: response.statusCode,
        retryable: false,
      );
    } else if (response.statusCode >= 500) {
      throw ApiException(
        'Server error', 
        ApiErrorType.serverError,
        statusCode: response.statusCode,
        retryable: true,
      );
    } else {
      throw ApiException(
        'API Error: ${response.statusCode} ${response.body}', 
        ApiErrorType.unknown,
        statusCode: response.statusCode,
        retryable: false,
      );
    }
  }
  
  /// Generate cache key based on request details
  String _getCacheKey(String method, String path, [Map<String, dynamic>? body]) {
    if (body != null) {
      return '$method:$path:${jsonEncode(body)}';
    }
    return '$method:$path';
  }
  
  /// Clear all cached responses
  void clearCache() {
    _responseCache.clear();
  }
  
  /// Clear specific cached response
  void clearCacheFor(String method, String path, [Map<String, dynamic>? body]) {
    final cacheKey = _getCacheKey(method, path, body);
    _responseCache.remove(cacheKey);
  }
}

class CachedResponse {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration ttl;

  CachedResponse({required this.data, required this.timestamp, required this.ttl});

  bool isExpired() {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final bool retryable;

  ApiException(this.message, this.type, {this.statusCode, this.retryable = false});
}

enum ApiErrorType {
  offline,
  unauthorized,
  notFound,
  serverError,
  parseError,
  unknown,
}
