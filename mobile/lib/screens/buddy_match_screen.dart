import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/buddies_service.dart';
import '../models/pnr_result.dart';
import '../models/buddy_profile.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';

class BuddyMatchScreen extends StatefulWidget {
  const BuddyMatchScreen({super.key});

  @override
  State<BuddyMatchScreen> createState() => _BuddyMatchScreenState();
}

class _BuddyMatchScreenState extends State<BuddyMatchScreen> {
  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );
  late final BuddiesService _buddiesService;

  List<BuddyProfile> _buddies = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _requestedBuddyIds = {};

  @override
  void initState() {
    super.initState();
    _buddiesService = BuddiesService(apiClient: _apiClient);
    _loadBuddies();
  }

  Future<void> _loadBuddies() async {
    final pnrResult = ModalRoute.of(context)!.settings.arguments as PnrResult;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final buddies = await _buddiesService.search(pnrResult.pnr);
      setState(() {
        _buddies = buddies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _requestToConnect(BuddyProfile buddy) async {
    final pnrResult = ModalRoute.of(context)!.settings.arguments as PnrResult;

    try {
      await _buddiesService.request(pnrResult.pnr, buddy.id);
      setState(() {
        _requestedBuddyIds.add(buddy.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Potential Buddies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'These passengers have confirmed tickets on your train and class.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBuddies,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_buddies.isEmpty) {
      return const Center(
        child: Text(
          'No confirmed co‑passengers matched yet.\nWe’ll notify you if someone appears.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _buddies.length,
      itemBuilder: (context, index) {
        final buddy = _buddies[index];
        final isRequested = _requestedBuddyIds.contains(buddy.id);
        return _BuddyCard(
          buddy: buddy,
          isRequested: isRequested,
          onRequest: () => _requestToConnect(buddy),
        );
      },
    );
  }
}

class _BuddyCard extends StatelessWidget {
  final BuddyProfile buddy;
  final bool isRequested;
  final VoidCallback onRequest;

  const _BuddyCard({
    required this.buddy,
    required this.isRequested,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Confirmed Passenger',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              buddy.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Age: ${buddy.ageGroup} • Gender: ${buddy.gender}'),
            const SizedBox(height: 4),
            Text('Languages: ${buddy.languages.join(', ')}'),
            const SizedBox(height: 8),
            Text('${buddy.from} → ${buddy.to}'),
            const SizedBox(height: 16),
            if (isRequested)
              const ElevatedButton(
                onPressed: null,
                child: Text('Requested'),
              )
            else
              ElevatedButton(
                onPressed: onRequest,
                child: const Text('Request to Connect'),
              ),
          ],
        ),
      ),
    );
  }
}
