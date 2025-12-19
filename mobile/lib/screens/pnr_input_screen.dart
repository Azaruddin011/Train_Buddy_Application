import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/pnr_service.dart';
import '../models/pnr_result.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';

class PnrInputScreen extends StatefulWidget {
  const PnrInputScreen({super.key});

  @override
  State<PnrInputScreen> createState() => _PnrInputScreenState();
}

class _PnrInputScreenState extends State<PnrInputScreen> {
  final _pnrController = TextEditingController();
  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );
  late final PnrService _pnrService;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pnrService = PnrService(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final pnr = _pnrController.text.trim();
    if (pnr.length != 10) {
      setState(() => _errorMessage = 'Enter a valid 10‑digit PNR.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _pnrService.lookup(pnr);
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/journey-clarity',
          arguments: result,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Check Your Journey')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter your PNR to get live waiting list clarity.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _pnrController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'PNR',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || _pnrController.text.length != 10
                  ? null
                  : _checkStatus,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Check Status'),
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
