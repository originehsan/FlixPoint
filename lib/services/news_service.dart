import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movieticket/models/news_article_model.dart';
import 'package:movieticket/services/news_cache_service.dart';
import 'package:movieticket/services/recommendation_service.dart';
import 'package:movieticket/utils/constants.dart';

class NewsService {
  static final NewsService _instance =
      NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final NewsCacheService _hiveCache = NewsCacheService();
  final RecommendationService _recommendation =
      RecommendationService();

  // ═══════════════════════════════════
  // FETCH ALL NEWS
  // Stale While Revalidate pattern:
  // 1. Return Hive cache instantly
  // 2. Fetch fresh in background
  // 3. Update when ready
  // ═══════════════════════════════════
  Future<List<NewsArticle>> fetchAllNews({
    bool forceRefresh = false,
  }) async {
    // Check Hive cache first
    final isCacheValid =
        await _hiveCache.isCacheValid();
    final cachedArticles =
        await _hiveCache.getCachedArticles();

    debugPrint(
      '📦 Cache valid: $isCacheValid, '
      'articles: ${cachedArticles.length}',
    );

    // Return cache immediately if valid
    if (!forceRefresh &&
        isCacheValid &&
        cachedArticles.isNotEmpty) {
      debugPrint('✅ Serving from Hive cache');
      return cachedArticles;
    }

    // Fetch fresh from API
    final fresh = await _fetchFromApi();

    if (fresh.isNotEmpty) {
      // Save to Hive
      await _hiveCache.saveArticles(fresh);
      return fresh;
    }

    // API failed but have stale cache
    if (cachedArticles.isNotEmpty) {
      debugPrint(
        '⚠️ API failed, serving stale cache',
      );
      return cachedArticles;
    }

    // Nothing available
    return [];
  }

  // ═══════════════════════════════════
  // FETCH FROM API
  // Single call with smart query
  // Falls back to simple bollywood
  // ═══════════════════════════════════
  Future<List<NewsArticle>> _fetchFromApi() async {
    try {
      final queries = await _recommendation
          .getPersonalizedQueries();

      // Build safe query
      // Use simple OR of bollywood-prefixed terms
      final safeQuery = queries
          .take(2)
          .join(' OR ');

      final finalQuery = safeQuery.isEmpty
          ? 'bollywood'
          : safeQuery;

      debugPrint('🔍 API query: $finalQuery');

      final response = await _dio.get(
        '$gNewsBaseUrl/search',
        queryParameters: {
          'q': finalQuery,
          'lang': 'en',
          'country': 'in',
          'max': 10,
          'page': 1,
          'sortby': 'publishedAt',
          'apikey': gNewsApiKey,
        },
      );

      debugPrint(
        '📡 Status: ${response.statusCode}',
      );

      final articles = _parseArticles(response.data);
      debugPrint('✅ Fetched: ${articles.length}');

      if (articles.isNotEmpty) return articles;

      // Empty result → try simple fallback
      return await _simpleFetch('bollywood');
    } catch (e) {
      debugPrint('❌ API error: $e');
      // Try simple bollywood query
      return await _simpleFetch('bollywood');
    }
  }

  // ═══════════════════════════════════
  // SIMPLE FETCH — guaranteed to work
  // ═══════════════════════════════════
  Future<List<NewsArticle>> _simpleFetch(
    String query,
  ) async {
    try {
      debugPrint('🔄 Simple fetch: $query');

      final response = await _dio.get(
        '$gNewsBaseUrl/search',
        queryParameters: {
          'q': query,
          'lang': 'en',
          'country': 'in',
          'max': 10,
          'page': 1,
          'sortby': 'publishedAt',
          'apikey': gNewsApiKey,
        },
      );

      final articles = _parseArticles(response.data);
      debugPrint(
        '✅ Simple fetch count: ${articles.length}',
      );
      return articles;
    } catch (e) {
      debugPrint('❌ Simple fetch error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════
  // CATEGORY FILTER — LOCAL ONLY
  // Zero extra API calls ✅
  // ═══════════════════════════════════
  Future<List<NewsArticle>> getNewsByCategory(
    String category,
  ) async {
    final all = await fetchAllNews();
    if (category == 'All') return all;

    final keyword = _categoryKeyword(category);
    if (keyword.isEmpty) return all;

    final filtered = all.where((article) {
      final text =
          '${article.title} ${article.description}'
              .toLowerCase();
      return text.contains(keyword);
    }).toList();

    // Never return empty — fallback to all
    return filtered.isEmpty ? all : filtered;
  }

  String _categoryKeyword(String category) {
    switch (category) {
      case 'Bollywood':
        return 'bollywood';
      case 'Hollywood':
        return 'hollywood';
      case 'Reviews':
        return 'review';
      case 'Trailers':
        return 'trailer';
      case 'Awards':
        return 'award';
      default:
        return '';
    }
  }

  // ═══════════════════════════════════
  // LOAD MORE — user tap only
  // ═══════════════════════════════════
  Future<List<NewsArticle>> loadMore(
    String category,
    int page,
  ) async {
    try {
      debugPrint('📄 Load more page: $page');

      final queries = await _recommendation
          .getPersonalizedQueries();

      final safeQuery = queries.take(2).join(' OR ');
      final finalQuery =
          safeQuery.isEmpty ? 'bollywood' : safeQuery;

      final response = await _dio.get(
        '$gNewsBaseUrl/search',
        queryParameters: {
          'q': finalQuery,
          'lang': 'en',
          'country': 'in',
          'max': 10,
          'page': page,
          'sortby': 'publishedAt',
          'apikey': gNewsApiKey,
        },
      );

      return _parseArticles(response.data);
    } catch (e) {
      debugPrint('❌ Load more error: $e');
      return [];
    }
  }

  List<NewsArticle> _parseArticles(dynamic data) {
    try {
      final articles = data['articles'] as List? ?? [];
      final parsed = articles
          .map(
            (a) => NewsArticle.fromJson(
              a as Map<String, dynamic>,
            ),
          )
          .where(
            (a) =>
                a.title.isNotEmpty &&
                a.url.isNotEmpty,
          )
          .toList();

      debugPrint('🔢 Parsed: ${parsed.length}');
      return parsed;
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      return [];
    }
  }

  // Force refresh — clears Hive cache
  Future<void> clearCache() async {
    await _hiveCache.clearCache();
    debugPrint('🗑️ News cache cleared');
  }
}