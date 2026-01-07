import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserService _userService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  Map<String, dynamic>? _user;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String _selectedAgeGroup = '18-25';
  final List<String> _ageGroups = ['Under 18', '18-25', '26-35', '36-50', 'Above 50'];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      baseUrl: AppConfig.backendBaseUrl,
      tokenProvider: () => TokenStore.token,
    );
    _userService = UserService(apiClient: apiClient);

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _aadhaarController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _userService.getProfile();
      final user = (res['user'] is Map<String, dynamic>) ? (res['user'] as Map<String, dynamic>) : null;

      if (user != null) {
        _user = user;
        _nameController.text = (user['name'] ?? '').toString();
        _emailController.text = (user['email'] ?? '').toString();
        _aadhaarController.text = (user['aadhaarNumber'] ?? '').toString();
        _emergencyContactController.text = (user['emergencyContact'] ?? '').toString();

        final age = (user['ageGroup'] ?? '').toString();
        if (_ageGroups.contains(age)) {
          _selectedAgeGroup = age;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String? _absolutePhotoUrl() {
    final url = _user?['profilePhotoUrl']?.toString();
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (url.startsWith('/')) {
      return '${AppConfig.backendBaseUrl}$url';
    }

    return '${AppConfig.backendBaseUrl}/$url';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final res = await _userService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        ageGroup: _selectedAgeGroup,
        emergencyContact: _emergencyContactController.text.trim().isNotEmpty
            ? _emergencyContactController.text.trim()
            : null,
        aadhaarNumber: _aadhaarController.text.trim().isNotEmpty ? _aadhaarController.text.trim() : null,
      );

      final user = (res['user'] is Map<String, dynamic>) ? (res['user'] as Map<String, dynamic>) : null;
      if (user != null) {
        _user = user;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  Future<void> _changePhoto() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _isSaving = true;
      });

      final res = await _userService.updateProfilePhoto(
        photoFile: File(picked.path),
      );
      final user = (res['user'] is Map<String, dynamic>) ? (res['user'] as Map<String, dynamic>) : null;
      if (user != null) {
        _user = user;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload photo: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _absolutePhotoUrl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Center(
                    child: InkWell(
                      onTap: _changePhoto,
                      borderRadius: BorderRadius.circular(48),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, size: 44, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      (_user?['phoneNumber'] ?? _user?['phone'] ?? '').toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final v = value.trim();
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Please enter a valid email';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _aadhaarController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar Number (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                              if (digitsOnly.length != 12) {
                                return 'Please enter a valid 12-digit Aadhaar number';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedAgeGroup,
                          decoration: const InputDecoration(
                            labelText: 'Age Group',
                            border: OutlineInputBorder(),
                          ),
                          items: _ageGroups
                              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedAgeGroup = v;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emergencyContactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Emergency Contact (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
