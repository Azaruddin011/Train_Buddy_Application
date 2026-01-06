import 'api_client.dart';

class OffersService {
  final ApiClient _apiClient;

  OffersService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> createOffer({
    required String pnr,
    required int seatsAvailable,
    String? note,
  }) async {
    final json = await _apiClient.post('/offers/create', {
      'pnr': pnr,
      'seatsAvailable': seatsAvailable,
      if (note != null) 'note': note,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Offer creation failed');
    }
    return json['offer'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> searchOffers({required String pnr}) async {
    final json = await _apiClient.get('/offers/search?pnr=${Uri.encodeComponent(pnr)}');
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Offer search failed');
    }
    final list = json['offers'];
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> requestOffer({
    required String pnr,
    required String offerId,
    String? message,
  }) async {
    final json = await _apiClient.post('/offers/request', {
      'pnr': pnr,
      'offerId': offerId,
      if (message != null) 'message': message,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Offer request failed');
    }
    return json['request'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> incomingRequests({required String pnr}) async {
    final json = await _apiClient.get('/offers/requests/incoming?pnr=${Uri.encodeComponent(pnr)}');
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Failed to load incoming requests');
    }
    final list = json['requests'];
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> respond({required String requestId, required String action}) async {
    final json = await _apiClient.post('/offers/respond', {
      'requestId': requestId,
      'action': action,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Failed to respond');
    }
    return json['request'] as Map<String, dynamic>;
  }
}
