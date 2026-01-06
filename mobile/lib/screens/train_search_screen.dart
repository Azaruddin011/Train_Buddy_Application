import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';

class TrainSearchScreen extends StatefulWidget {
  const TrainSearchScreen({super.key});

  @override
  State<TrainSearchScreen> createState() => _TrainSearchScreenState();
}

class _TrainSearchScreenState extends State<TrainSearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );

  List<Map<String, String>> _allStations = [];
  Map<String, String> _codeToName = {};

  Timer? _fromDebounce;
  Timer? _toDebounce;
  List<Map<String, String>> _fromSuggestions = [];
  List<Map<String, String>> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _trains = [];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final raw = await rootBundle.loadString('assets/stations.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final stations = decoded
          .whereType<Map>()
          .map((s) {
            final name = (s['name'] ?? '').toString().trim();
            final code = (s['code'] ?? '').toString().trim().toUpperCase();
            final state = (s['state'] ?? '').toString().trim();
            return {
              'code': code,
              'name': name,
              'state': state,
            };
          })
          .where((s) => (s['code'] ?? '').isNotEmpty && (s['name'] ?? '').isNotEmpty)
          .toList();

      final map = <String, String>{};
      for (final s in stations) {
        final code = s['code'] ?? '';
        final name = s['name'] ?? '';
        if (code.isNotEmpty && name.isNotEmpty) {
          map[code] = name;
        }
      }

      if (!mounted) return;
      setState(() {
        _allStations = stations;
        _codeToName = map;
      });
    } catch (_) {
      // Ignore - app will fall back to backend station search
    }
  }

  Uri _buildIrctcUri({required String from, required String to}) {
    final fromCode = from.trim().toUpperCase();
    final toCode = to.trim().toUpperCase();

    // IRCTC does not provide a stable public deep-link for prefilled booking.
    // We open the official site and pass route as best-effort query params.
    return Uri.https('www.irctc.co.in', '/nget/train-search', {
      'from': fromCode,
      'to': toCode,
    });
  }

  Future<void> _openIrctc({required String from, required String to}) async {
    final uri = _buildIrctcUri(from: from, to: to);

    final ok = await canLaunchUrl(uri);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open IRCTC')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _fromDebounce?.cancel();
    _toDebounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  bool _looksLikeStationCode(String value) {
    final v = value.trim();
    return RegExp(r'^[A-Za-z]{2,5}$').hasMatch(v);
  }

  Future<List<Map<String, String>>> _fetchStations(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final qUpper = q.toUpperCase();
    final qLower = q.toLowerCase();
    final localMatches = _allStations
        .where((s) {
          final code = (s['code'] ?? '').toUpperCase();
          final name = (s['name'] ?? '').toLowerCase();
          return code.contains(qUpper) || name.contains(qLower);
        })
        .take(10)
        .toList();

    // If local station dataset is loaded, prefer it and skip the API.
    if (_allStations.isNotEmpty) {
      return localMatches;
    }

    try {
      final response = await _apiClient.get('/trains/stations?query=${Uri.encodeComponent(q)}');
      final stations = response['stations'];
      if (stations is! List) return localMatches;

      final remote = stations
          .whereType<Map>()
          .map((s) {
            final code = (s['code'] ?? '').toString().trim();
            final name = (s['name'] ?? '').toString().trim();
            final state = (s['state'] ?? '').toString().trim();
            return {
              'code': code,
              'name': name,
              'state': state,
            };
          })
          .where((s) => (s['code'] ?? '').isNotEmpty)
          .take(10)
          .toList();

      if (remote.isEmpty) return localMatches;
      return remote;
    } catch (_) {
      return localMatches;
    }
  }

  Future<String?> _resolveStationCode(String input) async {
    final v = input.trim();
    if (v.isEmpty) return null;
    if (_looksLikeStationCode(v)) return v.toUpperCase();

    final stations = await _fetchStations(v);
    if (stations.isEmpty) return null;
    return (stations.first['code'] ?? '').toUpperCase();
  }

  String? _stationNameForCode(String code) {
    final key = code.trim().toUpperCase();
    if (key.isEmpty) return null;
    return _codeToName[key];
  }

  void _onFromChanged(String value) {
    _fromDebounce?.cancel();
    final v = value.trim();

    if (v.length < 2) {
      setState(() {
        _fromSuggestions = [];
        _showFromSuggestions = false;
      });
      return;
    }

    _fromDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await _fetchStations(v);
        if (!mounted) return;
        setState(() {
          _fromSuggestions = results;
          _showFromSuggestions = results.isNotEmpty;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _fromSuggestions = [];
          _showFromSuggestions = false;
        });
      }
    });
  }

  void _onToChanged(String value) {
    _toDebounce?.cancel();
    final v = value.trim();

    if (v.length < 2) {
      setState(() {
        _toSuggestions = [];
        _showToSuggestions = false;
      });
      return;
    }

    _toDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await _fetchStations(v);
        if (!mounted) return;
        setState(() {
          _toSuggestions = results;
          _showToSuggestions = results.isNotEmpty;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _toSuggestions = [];
          _showToSuggestions = false;
        });
      }
    });
  }

  Widget _buildSuggestions({
    required List<Map<String, String>> items,
    required void Function(Map<String, String>) onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = items[index];
          final code = s['code'] ?? '';
          final name = s['name'] ?? '';
          final state = s['state'] ?? '';

          return ListTile(
            dense: true,
            title: Text('$name ($code)'),
            subtitle: state.isEmpty ? null : Text(state),
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }

  Future<void> _searchTrains() async {
    final fromInput = _fromController.text.trim();
    final toInput = _toController.text.trim();

    if (fromInput.isEmpty || toInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter both stations');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _trains = [];
    });

    try {
      final fromCode = await _resolveStationCode(fromInput);
      final toCode = await _resolveStationCode(toInput);

      if (fromCode == null || toCode == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please select valid stations (e.g., NDLS, BCT)';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await _apiClient.get(
        '/trains/search?from=$fromCode&to=$toCode',
      );
      
      if (mounted) {
        setState(() {
          _trains = response['trains'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Search'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  onChanged: _onFromChanged,
                  decoration: InputDecoration(
                    labelText: 'From Station',
                    hintText: 'e.g., NDLS (New Delhi)',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                    helperText: _looksLikeStationCode(_fromController.text)
                        ? (_stationNameForCode(_fromController.text) ?? '')
                        : null,
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                if (_showFromSuggestions)
                  _buildSuggestions(
                    items: _fromSuggestions,
                    onSelect: (s) {
                      _fromController.text = (s['code'] ?? '').toUpperCase();
                      setState(() {
                        _showFromSuggestions = false;
                        _fromSuggestions = [];
                      });
                    },
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _toController,
                  onChanged: _onToChanged,
                  decoration: InputDecoration(
                    labelText: 'To Station',
                    hintText: 'e.g., BCT (Mumbai Central)',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                    helperText: _looksLikeStationCode(_toController.text)
                        ? (_stationNameForCode(_toController.text) ?? '')
                        : null,
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                if (_showToSuggestions)
                  _buildSuggestions(
                    items: _toSuggestions,
                    onSelect: (s) {
                      _toController.text = (s['code'] ?? '').toUpperCase();
                      setState(() {
                        _showToSuggestions = false;
                        _toSuggestions = [];
                      });
                    },
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchTrains,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Search Trains',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _trains.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.train,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for trains between stations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trains.length,
                    itemBuilder: (context, index) {
                      final train = _trains[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A237E),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      train['trainNumber']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      train['trainName']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        train['departureTime']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        train['from']?.toString() ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Icon(Icons.arrow_forward, color: Colors.grey[400]),
                                      Text(
                                        train['duration']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        train['arrivalTime']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        train['to']?.toString() ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (train['runningDays'] != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Runs: ${train['runningDays']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openIrctc(
                                    from: _fromController.text,
                                    to: _toController.text,
                                  ),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Book on IRCTC'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
