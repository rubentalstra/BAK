import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SignedUrlCache {
  static const String cacheKey = 'signed_url_cache';

  // Load the cache from persistent storage (SharedPreferences)
  static Future<Map<String, _CachedUrl>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(cacheKey);
    if (cacheString != null) {
      final Map<String, dynamic> decoded = json.decode(cacheString);
      return decoded.map((key, value) {
        final cacheEntry = _CachedUrl.fromJson(value);
        return MapEntry(key, cacheEntry);
      });
    }
    return {};
  }

  // Save the cache to persistent storage (SharedPreferences)
  static Future<void> _saveCache(Map<String, _CachedUrl> cache) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString =
        json.encode(cache.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString(cacheKey, cacheString);
  }

  // Get cached URL if valid
  static Future<String?> getCachedUrl(String filePath) async {
    final cache = await _loadCache();
    final cachedUrl = cache[filePath];
    if (cachedUrl != null && cachedUrl.isValid()) {
      return cachedUrl.url;
    }
    return null;
  }

  // Cache a new URL with its expiration
  static Future<void> cacheUrl(
      String filePath, String url, Duration duration) async {
    final cache = await _loadCache();
    cache[filePath] = _CachedUrl(url, DateTime.now().add(duration));
    await _saveCache(cache);
  }

  // Clear all cached URLs
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
  }

  // Delete a specific cached URL
  static Future<void> deleteCachedUrl(String filePath) async {
    final cache = await _loadCache();
    if (cache.containsKey(filePath)) {
      cache.remove(filePath);
      await _saveCache(cache);
    }
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiration;

  _CachedUrl(this.url, this.expiration);

  bool isValid() {
    return DateTime.now().isBefore(expiration);
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'expiration': expiration.toIso8601String(),
      };

  factory _CachedUrl.fromJson(Map<String, dynamic> json) {
    return _CachedUrl(
      json['url'],
      DateTime.parse(json['expiration']),
    );
  }
}
