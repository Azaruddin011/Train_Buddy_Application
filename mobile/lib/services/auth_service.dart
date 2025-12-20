import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'token_store.dart';

class AuthService {
  final ApiClient _apiClient;
  String? _token;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  String? get token => _token;

  Future<void> sendOtp(String phone) async {
    final json = await _apiClient.post('/auth/send-otp', {'phone': phone});
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    final json = await _apiClient.post('/auth/verify-otp', {'phone': phone, 'otp': otp});
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Failed to verify OTP');
    }
    _token = json['token'];
    await TokenStore.save(_token);
  }

  Future<void> loadToken() async {
    await TokenStore.load();
    _token = TokenStore.token;
  }

  Future<void> logout() async {
    _token = null;
    await TokenStore.clear();
  }

  bool get isLoggedIn => _token != null;
}
