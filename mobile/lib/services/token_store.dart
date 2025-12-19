import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore._();

  static const _storage = FlutterSecureStorage();
  static String? _token;

  static String? get token => _token;

  static Future<void> load() async {
    _token = await _storage.read(key: 'auth_token');
  }

  static Future<void> save(String? token) async {
    _token = token;
    if (token == null) {
      await _storage.delete(key: 'auth_token');
    } else {
      await _storage.write(key: 'auth_token', value: token);
    }
  }

  static Future<void> clear() async {
    await save(null);
  }
}
