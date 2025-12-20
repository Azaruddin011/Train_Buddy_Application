import 'dart:convert';
import 'api_client.dart';
import '../models/payment.dart';

class PaymentsService {
  final ApiClient _apiClient;

  PaymentsService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Payment> createIntent(String pnr) async {
    final json = await _apiClient.post('/payments/create-intent', {'pnr': pnr});
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Payment intent failed');
    }
    return Payment.fromJson(json['payment']);
  }

  Future<Payment> confirm(String paymentId, String providerPaymentId, String providerSignature) async {
    final json = await _apiClient.post('/payments/confirm', {
      'paymentId': paymentId,
      'providerPaymentId': providerPaymentId,
      'providerSignature': providerSignature,
    });
    if (!json['success']) {
      throw Exception(json['message'] ?? 'Payment confirmation failed');
    }
    return Payment.fromJson(json['payment']);
  }
}
