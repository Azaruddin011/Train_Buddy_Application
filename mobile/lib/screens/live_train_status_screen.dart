import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';

class LiveTrainStatusScreen extends StatefulWidget {
  const LiveTrainStatusScreen({super.key});

  @override
  State<LiveTrainStatusScreen> createState() => _LiveTrainStatusScreenState();
}

class _LiveTrainStatusScreenState extends State<LiveTrainStatusScreen> {
  final _trainNumberController = TextEditingController();
  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _trainStatus;

  @override
  void dispose() {
    _trainNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final trainNumber = _trainNumberController.text.trim();

    if (trainNumber.isEmpty) {
      setState(() => _errorMessage = 'Please enter train number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _trainStatus = null;
    });

    try {
      final response = await _apiClient.get(
        '/trains/live-status?trainNumber=$trainNumber',
      );
      
      if (mounted) {
        setState(() {
          _trainStatus = response;
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
        title: const Text('Live Train Status'),
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
                  controller: _trainNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Train Number',
                    hintText: 'e.g., 12345',
                    prefixIcon: const Icon(Icons.train, color: Colors.white70),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkStatus,
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
                            'Check Status',
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
            child: _trainStatus == null && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter train number to check live status',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _trainStatus != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
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
                                            _trainStatus!['trainNumber']?.toString() ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _trainStatus!['trainName']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatusRow(
                                      'Current Location',
                                      _trainStatus!['currentLocation']?.toString() ?? 'N/A',
                                      Icons.location_on,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatusRow(
                                      'Delay',
                                      _trainStatus!['delay']?.toString() ?? 'On Time',
                                      Icons.schedule,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatusRow(
                                      'Last Updated',
                                      _trainStatus!['lastUpdated']?.toString() ?? 'N/A',
                                      Icons.update,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_trainStatus!['stations'] != null) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Station Updates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(_trainStatus!['stations'] as List).map((station) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: station['departed'] == true
                                          ? Colors.green
                                          : Colors.orange,
                                      child: Icon(
                                        station['departed'] == true
                                            ? Icons.check
                                            : Icons.schedule,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(station['stationName']?.toString() ?? ''),
                                    subtitle: Text(
                                      'Arrival: ${station['arrivalTime']} | Departure: ${station['departureTime']}',
                                    ),
                                    trailing: station['delay'] != null
                                        ? Text(
                                            station['delay'].toString(),
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
