import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';
import '../services/station_repository.dart';
import '../widgets/station_autocomplete_field.dart';

class SeatAvailabilityScreen extends StatefulWidget {
  const SeatAvailabilityScreen({super.key});

  @override
  State<SeatAvailabilityScreen> createState() => _SeatAvailabilityScreenState();
}

class _SeatAvailabilityScreenState extends State<SeatAvailabilityScreen> {
  final _trainNumberController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _dateController = TextEditingController();
  final _apiClient = ApiClient(
    baseUrl: AppConfig.backendBaseUrl,
    tokenProvider: () => TokenStore.token,
  );

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _availability;
  String _selectedClass = '3A';

  final List<String> _classes = ['1A', '2A', '3A', 'SL', 'CC', '2S'];

  @override
  void dispose() {
    _trainNumberController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final trainNumber = _trainNumberController.text.trim();
    final fromInput = _fromController.text.trim();
    final toInput = _toController.text.trim();
    final date = _dateController.text.trim();

    if (trainNumber.isEmpty || fromInput.isEmpty || toInput.isEmpty || date.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _availability = null;
    });

    try {
      await StationRepository.instance.ensureLoaded();
      final from = StationRepository.instance.resolveCodeFromInput(fromInput);
      final to = StationRepository.instance.resolveCodeFromInput(toInput);

      if (from == null || to == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please select valid stations (e.g., NDLS, MAS)';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await _apiClient.get(
        '/trains/seat-availability?trainNumber=$trainNumber&from=$from&to=$to&date=$date&class=$_selectedClass',
      );
      
      if (mounted) {
        setState(() {
          _availability = response;
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
        title: const Text('Seat Availability'),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StationAutocompleteField(
                        controller: _fromController,
                        labelText: 'From',
                        hintText: 'Type station name or code',
                        textStyle: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'From',
                          hintText: 'Type station name or code',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StationAutocompleteField(
                        controller: _toController,
                        labelText: 'To',
                        hintText: 'Type station name or code',
                        textStyle: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'To',
                          hintText: 'Type station name or code',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A237E),
                      style: const TextStyle(color: Colors.white),
                      items: _classes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedClass = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkAvailability,
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
                            'Check Availability',
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
            child: _availability == null && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Check seat availability for your journey',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _availability != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Train ${_availability!['trainNumber']} - ${_availability!['trainName']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildAvailabilityRow(
                                  'Class',
                                  _availability!['class']?.toString() ?? _selectedClass,
                                ),
                                const SizedBox(height: 8),
                                _buildAvailabilityRow(
                                  'Status',
                                  _availability!['status']?.toString() ?? 'N/A',
                                ),
                                const SizedBox(height: 8),
                                _buildAvailabilityRow(
                                  'Available Seats',
                                  _availability!['availableSeats']?.toString() ?? 'N/A',
                                ),
                                const SizedBox(height: 8),
                                _buildAvailabilityRow(
                                  'Fare',
                                  '₹${_availability!['fare']?.toString() ?? 'N/A'}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
