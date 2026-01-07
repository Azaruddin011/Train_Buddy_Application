import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';
import '../services/user_service.dart';

class ProfileIconButton extends StatefulWidget {
  const ProfileIconButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  State<ProfileIconButton> createState() => _ProfileIconButtonState();
}

class _ProfileIconButtonState extends State<ProfileIconButton> {
  late final UserService _userService;
  late Future<Map<String, dynamic>> _future;

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

  String? _absolutePhotoUrl(Map<String, dynamic>? user) {
    final url = user?['profilePhotoUrl']?.toString();
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (url.startsWith('/')) {
      return '${AppConfig.backendBaseUrl}$url';
    }

    return '${AppConfig.backendBaseUrl}/$url';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final user = snapshot.data?['user'] is Map<String, dynamic>
            ? (snapshot.data!['user'] as Map<String, dynamic>)
            : null;
        final photoUrl = _absolutePhotoUrl(user);

        return IconButton(
          onPressed: () async {
            await Navigator.pushNamed(context, '/profile');
            if (!mounted) return;
            setState(() {
              _future = _userService.getProfile();
            });
          },
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(Icons.person, size: 18, color: widget.iconColor ?? Colors.black54)
                : null,
          ),
        );
      },
    );
  }
}
