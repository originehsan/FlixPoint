import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:movieticket/models/news_article_model.dart';

class NewsCacheService {
  static final NewsCacheService _instance =
      NewsCacheService._internal();
  factory NewsCacheService() => _instance;
  NewsCacheService._internal();

  static const String _boxName = 'news_cache';
  static const String _articlesKey = 'articles';
  static const String _cachedAtKey = 'cached_at';
  static const int _ttlHours = 6;

  // Open Hive box
  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  // Check if cache is valid
  Future<bool> isCacheValid() async {
    try {
      final box = await _getBox();
      final cachedAt = box.get(_cachedAtKey) as int?;
      if (cachedAt == null) return false;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(
        cachedAt,
      );
      final diff = DateTime.now().difference(cachedTime);
      return diff.inHours < _ttlHours;
    } catch (e) {
      debugPrint('Cache validity check error: $e');
      return false;
    }
  }

  // Get cached articles
  Future<List<NewsArticle>> getCachedArticles() async {
    try {
      final box = await _getBox();
      final raw = box.get(_articlesKey);
      if (raw == null) return [];

      final list = (raw as List).cast<Map>();
      return list
          .map(
            (item) => NewsArticle.fromCache(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Get cache error: $e');
      return [];
    }
  }

  // Save articles to Hive
  Future<void> saveArticles(
    List<NewsArticle> articles,
  ) async {
    try {
      final box = await _getBox();
      final jsonList = articles
          .map((a) => a.toJson())
          .toList();

      await box.put(_articlesKey, jsonList);
      await box.put(
        _cachedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint(
        '💾 Saved ${articles.length} articles to Hive',
      );
    } catch (e) {
      debugPrint('Save cache error: $e');
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      debugPrint('🗑️ News cache cleared');
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }

  // Get cache age in minutes
  Future<int> getCacheAgeMinutes() async {
    try {
      final box = await _getBox();
      final cachedAt = box.get(_cachedAtKey) as int?;
      if (cachedAt == null) return -1;

      final cachedTime =
          DateTime.fromMillisecondsSinceEpoch(cachedAt);
      return DateTime.now()
          .difference(cachedTime)
          .inMinutes;
    } catch (_) {
      return -1;
    }
  }
}