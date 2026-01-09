import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final UserService _userService;
  late Future<Map<String, dynamic>> _future;

  bool _saving = false;
  bool _hydrated = false;
  String? _error;
  String? _success;

  String _seatPreference = 'no preference';
  String _dietaryPreference = 'no preference';
  bool _specialAssistance = false;

  final List<String> _allTrainClasses = const ['SL', '3A', '2A', '1A'];
  final Set<String> _selectedTrainClasses = {'SL', '3A', '2A', '1A'};

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      baseUrl: AppConfig.backendBaseUrl,
      tokenProvider: () => TokenStore.token,
    );
    _userService = UserService(apiClient: apiClient);
    _future = _userService.getProfile();
  }

  void _hydrateFromProfile(Map<String, dynamic>? user) {
    final preferences = user?['preferences'];
    if (preferences is! Map) return;

    final seat = preferences['seatPreference']?.toString();
    final dietary = preferences['dietaryPreference']?.toString();
    final assistance = preferences['specialAssistance'];
    final trainClasses = preferences['trainClasses'];

    if (seat != null && seat.isNotEmpty) {
      _seatPreference = seat;
    }
    if (dietary != null && dietary.isNotEmpty) {
      _dietaryPreference = dietary;
    }
    if (assistance is bool) {
      _specialAssistance = assistance;
    }
    if (trainClasses is List) {
      _selectedTrainClasses
        ..clear()
        ..addAll(trainClasses.map((e) => e.toString()).where((e) => e.isNotEmpty));
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      await _userService.updatePreferences(
        seatPreference: _seatPreference,
        dietaryPreference: _dietaryPreference,
        specialAssistance: _specialAssistance,
        trainClasses: _selectedTrainClasses.toList(),
      );

      setState(() {
        _saving = false;
        _success = 'Settings saved.';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final user = snapshot.data?['user'] is Map<String, dynamic>
              ? (snapshot.data!['user'] as Map<String, dynamic>)
              : null;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load settings: ${snapshot.error}'));
          }

          if (!_hydrated) {
            _hydrateFromProfile(user);
            _hydrated = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 12),
              ],
              if (_success != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(_success!, style: const TextStyle(color: Colors.green)),
                ),
                const SizedBox(height: 12),
              ],

              const Text('Seat Preference', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _seatPreference,
                items: const [
                  DropdownMenuItem(value: 'no preference', child: Text('No preference')),
                  DropdownMenuItem(value: 'lower', child: Text('Lower')),
                  DropdownMenuItem(value: 'middle', child: Text('Middle')),
                  DropdownMenuItem(value: 'upper', child: Text('Upper')),
                  DropdownMenuItem(value: 'side lower', child: Text('Side lower')),
                  DropdownMenuItem(value: 'side upper', child: Text('Side upper')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _seatPreference = v;
                  });
                },
              ),

              const SizedBox(height: 20),
              const Text('Train Classes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTrainClasses.map((c) {
                  final selected = _selectedTrainClasses.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTrainClasses.add(c);
                        } else {
                          _selectedTrainClasses.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Text('Dietary Preference', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _dietaryPreference,
                items: const [
                  DropdownMenuItem(value: 'no preference', child: Text('No preference')),
                  DropdownMenuItem(value: 'veg', child: Text('Veg')),
                  DropdownMenuItem(value: 'non-veg', child: Text('Non-veg')),
                  DropdownMenuItem(value: 'jain', child: Text('Jain')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _dietaryPreference = v;
                  });
                },
              ),

              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Special Assistance'),
                value: _specialAssistance,
                onChanged: (v) {
                  setState(() {
                    _specialAssistance = v;
                  });
                },
              ),

              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.brush_outlined),
                title: const Text('Preview new UI design'),
                subtitle: const Text('See the new Home design sample'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/home-preview');
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
