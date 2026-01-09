import 'dart:convert';
import 'dart:async';
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
    String? phoneNumber,
    String? name,
    String? email,
    String? ageGroup,
    String? emergencyContact,
    String? aadhaarNumber,
  }) async {
    final response = await _apiClient.post(
      '/users/profile',
      {
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (ageGroup != null) 'ageGroup': ageGroup,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (aadhaarNumber != null) 'aadhaarNumber': aadhaarNumber,
      },
    );
    
    return response;
  }
  
  /// Get user profile
  Future<Map<String, dynamic>> getProfile({String? phoneNumber}) async {
    final path = phoneNumber != null
        ? '/users/profile?phoneNumber=$phoneNumber'
        : '/users/profile';
    final response = await _apiClient.get(path);
    
    return response;
  }
  
  /// Update user preferences
  Future<Map<String, dynamic>> updatePreferences({
    String? phoneNumber,
    String? seatPreference,
    List<String>? trainClasses,
    String? dietaryPreference,
    bool? specialAssistance,
  }) async {
    final response = await _apiClient.post(
      '/users/preferences',
      {
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
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
      {
        'phoneNumber': phoneNumber,
        if (idVerified != null) 'idVerified': idVerified,
        if (idType != null) 'idType': idType,
        if (socialMediaLinked != null) 'socialMediaLinked': socialMediaLinked,
      },
    );
    
    return response;
  }
  
  /// Upload profile photo
  /// Uploads an image file as multipart/form-data
  Future<Map<String, dynamic>> updateProfilePhoto({
    String? phoneNumber,
    required File photoFile,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/users/photo');
    final request = http.MultipartRequest('POST', uri);

    final token = TokenStore.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (phoneNumber != null) {
      request.fields['phoneNumber'] = phoneNumber;
    }
    request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

    http.StreamedResponse streamed;
    String body;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 45));
      body = await streamed.stream.bytesToString().timeout(const Duration(seconds: 45));
    } on SocketException catch (e) {
      throw ApiException('Network error while uploading photo: ${e.message}', ApiErrorType.serverError);
    } on TimeoutException {
      throw ApiException('Upload timed out. Please try a smaller photo or try again.', ApiErrorType.serverError);
    }

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        throw ApiException(decoded['message'].toString(), ApiErrorType.serverError,
            statusCode: streamed.statusCode);
      }
    } catch (_) {
      // ignore
    }

    final trimmedBody = body.trim();
    final snippet = trimmedBody.length > 200 ? trimmedBody.substring(0, 200) : trimmedBody;
    throw ApiException(
      'Photo upload failed (HTTP ${streamed.statusCode})${snippet.isNotEmpty ? ': $snippet' : ''}',
      ApiErrorType.serverError,
      statusCode: streamed.statusCode,
    );
  }
}
