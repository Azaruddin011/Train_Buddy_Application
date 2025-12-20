import 'dart:convert';
import 'api_client.dart';
import '../models/pnr_result.dart';

class PnrService {
  final ApiClient _apiClient;

  PnrService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<PnrResult> lookup(String pnr) async {
    final json = await _apiClient.post('/pnr/lookup', {'pnr': pnr});
    if (!json['success']) {
      throw Exception(json['message'] ?? 'PNR lookup failed');
    }
    return PnrResult.fromJson(json);
  }
}
