import 'dart:convert';
import 'api_client.dart';
import '../models/buddy_profile.dart';

class BuddiesService {
  final ApiClient _apiClient;

  BuddiesService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<BuddyProfile>> search(String pnr, {Map<String, dynamic>? filters}) async {
    final json = await _apiClient.post('/buddies/search', {
      'pnr': pnr,
      if (filters != null) 'filters': filters,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Buddy search failed');
    }
    final buddiesJson = json['buddies'] as List;
    return buddiesJson.map((e) => BuddyProfile.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> request(String pnr, String buddyId, {String? message}) async {
    final json = await _apiClient.post('/buddies/request', {
      'pnr': pnr,
      'buddyId': buddyId,
      if (message != null) 'message': message,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Buddy request failed');
    }
    return json['request'];
  }

  Future<Map<String, dynamic>> respond(String requestId, String action) async {
    final json = await _apiClient.post('/buddies/respond', {
      'requestId': requestId,
      'action': action,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Buddy response failed');
    }
    return json['request'];
  }
}
