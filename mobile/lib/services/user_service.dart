import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_client.dart';
import 'token_store.dart';

class UserService {
  final ApiClient _apiClient;
  
  UserService({required ApiClient apiClient}) : _apiClient = apiClient;
  
  /// Create or update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String phoneNumber,
    String? name,
    String? email,
    String? ageGroup,
    String? emergencyContact,
  }) async {
    final response = await _apiClient.post(
      '/users/profile',
      body: {
        'phoneNumber': phoneNumber,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (ageGroup != null) 'ageGroup': ageGroup,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
      },
    );
    
    return response;
  }
  
  /// Get user profile
  Future<Map<String, dynamic>> getProfile({required String phoneNumber}) async {
    final response = await _apiClient.get(
      '/users/profile?phoneNumber=$phoneNumber',
    );
    
    return response;
  }
  
  /// Update user preferences
  Future<Map<String, dynamic>> updatePreferences({
    required String phoneNumber,
    String? seatPreference,
    List<String>? trainClasses,
    String? dietaryPreference,
    bool? specialAssistance,
  }) async {
    final response = await _apiClient.post(
      '/users/preferences',
      body: {
        'phoneNumber': phoneNumber,
        if (seatPreference != null) 'seatPreference': seatPreference,
        if (trainClasses != null) 'trainClasses': trainClasses,
        if (dietaryPreference != null) 'dietaryPreference': dietaryPreference,
        if (specialAssistance != null) 'specialAssistance': specialAssistance,
      },
    );
    
    return response;
  }
  
  /// Update verification status
  Future<Map<String, dynamic>> updateVerification({
    required String phoneNumber,
    bool? idVerified,
    String? idType,
    bool? socialMediaLinked,
  }) async {
    final response = await _apiClient.post(
      '/users/verification',
      body: {
        'phoneNumber': phoneNumber,
        if (idVerified != null) 'idVerified': idVerified,
        if (idType != null) 'idType': idType,
        if (socialMediaLinked != null) 'socialMediaLinked': socialMediaLinked,
      },
    );
    
    return response;
  }
  
  /// Upload profile photo
  /// Note: In a real app, this would handle file upload
  /// For now, we'll just send a URL
  Future<Map<String, dynamic>> updateProfilePhoto({
    required String phoneNumber,
    required String photoUrl,
  }) async {
    final response = await _apiClient.post(
      '/users/photo',
      body: {
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
      },
    );
    
    return response;
  }
}
