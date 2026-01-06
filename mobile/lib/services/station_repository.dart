import 'dart:convert';

import 'package:flutter/services.dart';

class StationRepository {
  StationRepository._();

  static final StationRepository instance = StationRepository._();

  bool _loaded = false;
  final List<Map<String, String>> _stations = [];
  final Map<String, String> _codeToName = {};

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString('assets/stations.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _loaded = true;
      return;
    }

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

    _stations
      ..clear()
      ..addAll(stations);

    _codeToName
      ..clear()
      ..addEntries(stations.map((s) => MapEntry(s['code']!, s['name']!)));

    _loaded = true;
  }

  String? nameForCode(String code) {
    final key = code.trim().toUpperCase();
    if (key.isEmpty) return null;
    return _codeToName[key];
  }

  bool looksLikeStationCode(String value) {
    final v = value.trim();
    return RegExp(r'^[A-Za-z]{2,5}$').hasMatch(v);
  }

  List<Map<String, String>> searchLocal(String query, {int limit = 10}) {
    final q = query.trim();
    if (q.length < 2) return [];

    final qUpper = q.toUpperCase();
    final qLower = q.toLowerCase();

    return _stations
        .where((s) {
          final code = (s['code'] ?? '').toUpperCase();
          final name = (s['name'] ?? '').toLowerCase();
          return code.contains(qUpper) || name.contains(qLower);
        })
        .take(limit)
        .toList();
  }

  String? resolveCodeFromInput(String input) {
    final v = input.trim();
    if (v.isEmpty) return null;
    if (looksLikeStationCode(v)) return v.toUpperCase();

    final matches = searchLocal(v, limit: 1);
    if (matches.isEmpty) return null;
    return (matches.first['code'] ?? '').toUpperCase();
  }
}
