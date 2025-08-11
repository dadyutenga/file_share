import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/FileModels.dart';

class CacheManager {
  static const String _userStatsKey = 'cached_user_stats';
  static const String _userInfoKey = 'cached_user_info';
  static const String _lastCacheUpdateKey = 'last_cache_update';

  // Cache duration in minutes
  static const int _cacheDurationMinutes = 30;

  // Cache user stats
  static Future<void> cacheUserStats(UserStats userStats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStatsKey, jsonEncode(userStats.toJson()));
    await prefs.setInt(
      _lastCacheUpdateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Cache user info
  static Future<void> cacheUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, jsonEncode(userInfo.toJson()));
  }

  // Get cached user stats
  static Future<UserStats?> getCachedUserStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if cache is still valid
    final lastUpdate = prefs.getInt(_lastCacheUpdateKey);
    if (lastUpdate != null) {
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime).inMinutes;

      if (difference > _cacheDurationMinutes) {
        // Cache expired, remove it
        await clearCache();
        return null;
      }
    }

    final cachedData = prefs.getString(_userStatsKey);
    if (cachedData != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(cachedData);
        return UserStats.fromJson(json);
      } catch (e) {
        // Invalid cache data, remove it
        await clearCache();
        return null;
      }
    }
    return null;
  }

  // Get cached user info
  static Future<UserInfo?> getCachedUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_userInfoKey);
    if (cachedData != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(cachedData);
        return UserInfo.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clear all cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userStatsKey);
    await prefs.remove(_userInfoKey);
    await prefs.remove(_lastCacheUpdateKey);
  }

  // Check if cache is valid
  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastCacheUpdateKey);
    if (lastUpdate != null) {
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime).inMinutes;
      return difference <= _cacheDurationMinutes;
    }
    return false;
  }
}
