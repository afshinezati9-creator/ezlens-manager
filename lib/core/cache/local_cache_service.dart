import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local JSON cache for list/detail screens.
///
/// Flow:
/// 1) [read] instantly for UI
/// 2) network fetch in background
/// 3) [write] then UI refreshes
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _p() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Read decoded JSON (Map or List) or null if missing/corrupt.
  Future<dynamic> read(String key) async {
    try {
      final prefs = await _p();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('LocalCache read error ($key): $e');
      return null;
    }
  }

  /// Write any JSON-encodable value.
  Future<void> write(String key, Object? value) async {
    try {
      final prefs = await _p();
      if (value == null) {
        await prefs.remove(key);
        return;
      }
      await prefs.setString(key, jsonEncode(value));
      await prefs.setInt('${key}__ts', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('LocalCache write error ($key): $e');
    }
  }

  Future<int?> writtenAt(String key) async {
    final prefs = await _p();
    return prefs.getInt('${key}__ts');
  }

  Future<bool> has(String key) async {
    final prefs = await _p();
    return prefs.containsKey(key);
  }

  Future<void> remove(String key) async {
    final prefs = await _p();
    await prefs.remove(key);
    await prefs.remove('${key}__ts');
  }

  /// Remove every key that starts with [CacheKeys.prefix].
  Future<void> clearAllEzLensCache() async {
    final prefs = await _p();
    final keys = prefs.getKeys().where((k) => k.startsWith('ezlens_cache_v1_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
