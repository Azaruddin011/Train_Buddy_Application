import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/payments_service.dart';
import '../models/pnr_result.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );
  late final PaymentsService _paymentsService;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _paymentsService = PaymentsService(apiClient: _apiClient);
  }

  Future<void> _payAndProceed() async {
    final pnrResult = ModalRoute.of(context)!.settings.arguments as PnrResult;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mock payment intent creation
      await _paymentsService.createIntent(pnrResult.pnr);
      // Mock success (no real provider integration)
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/buddy-match',
          arguments: pnrResult,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pnrResult = ModalRoute.of(context)!.settings.arguments as PnrResult;

    final journey = pnrResult.journey;
    final maskedPnr = '********${pnrResult.pnr.substring(pnrResult.pnr.length - 2)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Premium WL Coordination')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Premium WL Coordination – ₹399',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'For this journey only',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Journey summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${journey.trainNumber} ${journey.trainName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${journey.from} → ${journey.to}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${journey.boardingDate} • ${journey.trainClass}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PNR: $maskedPnr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // What’s included
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What’s included',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _Bullet(text: 'Show confirmed co-passengers on your route'),
                    _Bullet(text: 'Send request; connection only on consent'),
                    _Bullet(text: 'Support basic comfort preferences'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reassurance
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You are NOT paying for ticket confirmation.\nYou are paying for safe, consent‑based coordination.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Payment button
            ElevatedButton(
              onPressed: _isLoading ? null : _payAndProceed,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Pay ₹399 & Find Buddy'),
            ),
            const SizedBox(height: 16),
            Text(
              'UPI / Card / Wallet accepted',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
