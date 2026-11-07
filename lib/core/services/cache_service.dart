import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service untuk menyimpan data secara lokal dengan expiration time
class CacheService {
  static CacheService? _instance;
  SharedPreferences? _prefs;

  CacheService._();

  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _storage {
    if (_prefs == null) {
      throw Exception('CacheService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Save data to cache with expiration time
  Future<void> setCache({
    required String key,
    required dynamic data,
    required Duration expiration,
  }) async {
    await init();
    
    final cacheData = {
      'data': data,
      'expiredAt': DateTime.now().add(expiration).millisecondsSinceEpoch,
    };
    
    await _storage.setString(key, jsonEncode(cacheData));
  }

  /// Get data from cache, returns null if expired or not found
  Future<T?> getCache<T>({
    required String key,
    required T Function(dynamic json) fromJson,
  }) async {
    await init();
    
    final jsonString = _storage.getString(key);
    if (jsonString == null) return null;

    try {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiredAt = cacheData['expiredAt'] as int;
      
      // Check if cache is expired
      if (DateTime.now().millisecondsSinceEpoch > expiredAt) {
        await removeCache(key);
        return null;
      }
      
      return fromJson(cacheData['data']);
    } catch (e) {
      await removeCache(key);
      return null;
    }
  }

  /// Get raw cached data without type conversion
  Future<dynamic> getRawCache(String key, {bool ignoreExpiration = false}) async {
    await init();
    
    final jsonString = _storage.getString(key);
    if (jsonString == null) return null;

    try {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiredAt = cacheData['expiredAt'] as int;
      
      if (!ignoreExpiration && DateTime.now().millisecondsSinceEpoch > expiredAt) {
        await removeCache(key);
        return null;
      }
      
      return cacheData['data'];
    } catch (e) {
      await removeCache(key);
      return null;
    }
  }

  /// Remove specific cache
  Future<void> removeCache(String key) async {
    await init();
    await _storage.remove(key);
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await init();
    final keys = _storage.getKeys().where((key) => key.startsWith('cache_'));
    for (final key in keys) {
      await _storage.remove(key);
    }
  }

  /// Check if cache exists and is valid
  Future<bool> hasValidCache(String key) async {
    await init();
    
    final jsonString = _storage.getString(key);
    if (jsonString == null) return false;

    try {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiredAt = cacheData['expiredAt'] as int;
      return DateTime.now().millisecondsSinceEpoch <= expiredAt;
    } catch (e) {
      return false;
    }
  }
}

/// Cache keys constants
class CacheKeys {
  static const String dashboard = 'cache_dashboard';
  static const String products = 'cache_products';
  static const String branches = 'cache_branches';
  static const String categories = 'cache_categories';
  static const String userProfile = 'cache_user_profile';
}

/// Cache durations
class CacheDurations {
  static const Duration dashboard = Duration(minutes: 5);
  static const Duration products = Duration(hours: 1);
  static const Duration branches = Duration(days: 1);
  static const Duration categories = Duration(hours: 1);
  static const Duration userProfile = Duration(minutes: 30);
}
