import 'dart:async';
import 'package:flutter/material.dart';

/// Service to monitor network connectivity status
class ConnectivityService with ChangeNotifier {
  bool _isOnline = true;
  DateTime? _lastOfflineTime;
  Timer? _connectivityCheckTimer;
  
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal() {
    // Start periodic connectivity check
    _startConnectivityCheck();
  }
  
  bool get isOnline => _isOnline;
  DateTime? get lastOfflineTime => _lastOfflineTime;
  
  void _startConnectivityCheck() {
    // Check connectivity every 10 seconds
    _connectivityCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkConnectivity();
    });
    
    // Initial check
    checkConnectivity();
  }
  
  Future<void> checkConnectivity() async {
    try {
      // Simple connectivity check by trying to fetch a small resource
      // In a real app, we'd use a connectivity plugin
      final result = await Future.any([
        _makeTestRequest(),
        Future.delayed(const Duration(seconds: 5), () => false),
      ]);
      
      final bool wasOnline = _isOnline;
      _isOnline = result == true;
      
      if (wasOnline && !_isOnline) {
        // Just went offline
        _lastOfflineTime = DateTime.now();
      }
      
      if (wasOnline != _isOnline) {
        // Notify listeners only if status changed
        notifyListeners();
      }
    } catch (e) {
      // If check fails, assume offline
      if (_isOnline) {
        _isOnline = false;
        _lastOfflineTime = DateTime.now();
        notifyListeners();
      }
    }
  }
  
  Future<bool> _makeTestRequest() async {
    try {
      // In a real app, we'd use http package to make a lightweight request
      // For simulation purposes, we'll just return true most of the time
      // with occasional false to simulate network drops
      await Future.delayed(const Duration(milliseconds: 500));
      return DateTime.now().millisecond % 10 != 0; // 10% chance of failure
    } catch (e) {
      return false;
    }
  }
  
  @override
  void dispose() {
    _connectivityCheckTimer?.cancel();
    super.dispose();
  }
}
