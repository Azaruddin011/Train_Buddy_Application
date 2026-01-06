import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/pnr_result.dart';
import '../services/api_client.dart';
import '../services/offers_service.dart';
import '../services/token_store.dart';

class OfferSeatScreen extends StatefulWidget {
  const OfferSeatScreen({super.key});

  @override
  State<OfferSeatScreen> createState() => _OfferSeatScreenState();
}

class _OfferSeatScreenState extends State<OfferSeatScreen> {
  final _noteController = TextEditingController();

  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );
  late final OffersService _offersService;

  int _seatsAvailable = 1;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _incoming = [];

  @override
  void initState() {
    super.initState();
    _offersService = OffersService(apiClient: _apiClient);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  PnrResult _pnrResult() {
    return ModalRoute.of(context)!.settings.arguments as PnrResult;
  }

  Future<void> _refresh() async {
    final pnr = _pnrResult().pnr;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pnrResult = _pnrResult();
      if (pnrResult.status.type == 'CNF') {
        final incoming = await _offersService.incomingRequests(pnr: pnr);
        setState(() {
          _incoming = incoming;
          _offers = [];
          _loading = false;
        });
      } else {
        final offers = await _offersService.searchOffers(pnr: pnr);
        setState(() {
          _offers = offers;
          _incoming = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createOffer() async {
    final pnrResult = _pnrResult();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _offersService.createOffer(
        pnr: pnrResult.pnr,
        seatsAvailable: _seatsAvailable,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer created')),
      );
      await _refresh();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _requestOffer(String offerId) async {
    final pnrResult = _pnrResult();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _offersService.requestOffer(pnr: pnrResult.pnr, offerId: offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent')),
      );
      await _refresh();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _respond(String requestId, String action) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _offersService.respond(requestId: requestId, action: action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $action')),
      );
      await _refresh();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pnrResult = _pnrResult();
    final isCnf = pnrResult.status.type == 'CNF';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCnf ? 'Offer Seat' : 'Find Seat Offers'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pnrResult.journey.trainNumber} ${pnrResult.journey.trainName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${pnrResult.journey.from} → ${pnrResult.journey.to}'),
                    const SizedBox(height: 4),
                    Text('${pnrResult.journey.boardingDate} • ${pnrResult.journey.trainClass}'),
                    const SizedBox(height: 8),
                    Text('Status: ${pnrResult.status.type}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_loading) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 12),
            if (isCnf) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create your offer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _seatsAvailable,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 seat')),
                          DropdownMenuItem(value: 2, child: Text('2 seats')),
                          DropdownMenuItem(value: 3, child: Text('3 seats')),
                          DropdownMenuItem(value: 4, child: Text('4 seats')),
                        ],
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _seatsAvailable = v ?? 1),
                        decoration: const InputDecoration(
                          labelText: 'Seats available to coordinate',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        enabled: !_loading,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _createOffer,
                          child: const Text('Publish Offer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Incoming requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_incoming.isEmpty && !_loading)
                const Text('No requests yet.'),
              ..._incoming.map((r) {
                final id = (r['_id'] ?? r['id'] ?? '').toString();
                final from = (r['fromPhoneNumber'] ?? '').toString();
                final status = (r['status'] ?? '').toString();
                final msg = (r['message'] ?? '').toString();
                return Card(
                  child: ListTile(
                    title: Text('From: $from'),
                    subtitle: Text(msg.isEmpty ? 'Status: $status' : 'Status: $status\n$msg'),
                    isThreeLine: msg.isNotEmpty,
                    trailing: status == 'PENDING'
                        ? PopupMenuButton<String>(
                            onSelected: (v) => _respond(id, v),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'ACCEPT', child: Text('Accept')),
                              PopupMenuItem(value: 'REJECT', child: Text('Reject')),
                            ],
                          )
                        : null,
                  ),
                );
              }),
            ] else ...[
              Text(
                'Available offers from confirmed passengers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_offers.isEmpty && !_loading)
                const Text('No offers found yet.'),
              ..._offers.map((o) {
                final id = (o['id'] ?? '').toString();
                final name = (o['displayName'] ?? '').toString();
                final seats = (o['seatsAvailable'] ?? 1).toString();
                final note = (o['note'] ?? '').toString();

                return Card(
                  child: ListTile(
                    title: Text('$name • Seats: $seats'),
                    subtitle: note.isEmpty ? null : Text(note),
                    trailing: ElevatedButton(
                      onPressed: _loading ? null : () => _requestOffer(id),
                      child: const Text('Request'),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
