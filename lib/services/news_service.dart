import 'package:dio/dio.dart';
import 'package:movieticket/models/news_article_model.dart';
import 'package:movieticket/services/news_cache_service.dart';
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
  final NewsCacheService _hiveCache =
      NewsCacheService();

  // Dynamic year — no hardcoded 2025
  static String get _year =>
      DateTime.now().year.toString();

  List<String> get _newsQueries => [
        'bollywood movies $_year',
        'bollywood news',
        'indian cinema',
        'hindi movies',
        'tamil movies',
        'tollywood',
      ];

  static const Map<String, String>
      _categoryQueries = {
    'Bollywood': 'bollywood movies',
    'Hollywood': 'hollywood movies',
    'Reviews': 'bollywood movie review',
    'Trailers': 'bollywood trailer',
    'Awards': 'filmfare awards bollywood',
  };

  Future<List<NewsArticle>> fetchAllNews({
    bool forceRefresh = false,
  }) async {
    final isCacheValid =
        await _hiveCache.isCacheValid();
    final cachedArticles =
        await _hiveCache.getCachedArticles();

    if (!forceRefresh &&
        isCacheValid &&
        cachedArticles.isNotEmpty) {
      return cachedArticles;
    }

    final fresh = await _fetchFromApi();

    if (fresh.isNotEmpty) {
      await _hiveCache.saveArticles(fresh);
      return fresh;
    }

    if (cachedArticles.isNotEmpty) {
      return cachedArticles;
    }

    return [];
  }

  Future<List<NewsArticle>> _fetchFromApi() async {
    for (final query in _newsQueries) {
      try {
        final articles =
            await _fetchQuery(query, page: 1);
        if (articles.isNotEmpty) return articles;
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  Future<List<NewsArticle>> _fetchQuery(
    String query, {
    int page = 1,
  }) async {
    final response = await _dio.get(
      '$gNewsBaseUrl/search',
      queryParameters: {
        'q': query,
        'lang': 'en',
        'country': 'in',
        'max': 10,
        'page': page,
        'sortby': 'publishedAt',
        'apikey': gNewsApiKey,
      },
    );
    return _parseArticles(response.data);
  }

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

  Future<List<NewsArticle>> loadMore(
    String category,
    int page,
  ) async {
    try {
      final query = category == 'All'
          ? _newsQueries.first
          : _categoryQueries[category] ??
              _newsQueries.first;
      return await _fetchQuery(query, page: page);
    } catch (_) {
      return [];
    }
  }

  // BUG 20 fix: deduplicate by URL
  List<NewsArticle> _parseArticles(dynamic data) {
    try {
      final articles =
          data['articles'] as List? ?? [];
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

      // Remove duplicates by URL
      final seen = <String>{};
      return parsed
          .where((a) => seen.add(a.url))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCache() async {
    await _hiveCache.clearCache();
  }
}