import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movieticket/services/cache_service.dart';
import 'package:movieticket/services/network_service.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/indian_filter.dart';

class TmdbService {
  static final TmdbService _instance =
      TmdbService._internal();
  factory TmdbService() => _instance;
  TmdbService._internal();

  late final Dio _dio;
  final CacheService _cache = CacheService();
  List<int> _nowPlayingIds = [];

  void initialize() {
    _dio = NetworkService().dio;
  }

  Dio get _client {
    try {
      return _dio;
    } catch (_) {
      return Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    }
  }

  Map<String, dynamic> get _baseParams => {
        'api_key': tmdbApiKey,
        'language': 'en-US',
      };

  Map<String, dynamic> get _indiaParams => {
        ..._baseParams,
        'region': 'IN',
        'page': 1,
      };

  // ═══════════════════════════════════
  // CACHED GET HELPER
  // ═══════════════════════════════════
  Future<dynamic> _cachedGet(
    String url, {
    Map<String, dynamic>? params,
    Duration cacheDuration =
        const Duration(minutes: 30),
  }) async {
    final cacheKey =
        '$url${params?.toString() ?? ''}';

    if (_cache.has(cacheKey)) {
      return _cache.get(cacheKey);
    }

    final response = await _client.get(
      url,
      queryParameters: params,
    );

    _cache.set(
      cacheKey,
      response.data,
      duration: cacheDuration,
    );
    return response.data;
  }

  // ═══════════════════════════════════
  // NOW PLAYING — Indian movies only
  // Fetches region=IN then filters
  // by original_language
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getNowPlaying() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/now_playing',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      final movies =
          results.cast<Map<String, dynamic>>();

      // Cache all IDs for isMovieNowPlayingInIndia
      _nowPlayingIds =
          movies.map((m) => m['id'] as int).toList();

      // Filter to Indian origin movies only
      return filterIndian(movies);
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // UPCOMING — Indian movies only
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getUpcoming() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/upcoming',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // POPULAR — Indian movies only
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getPopular() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/popular',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // TOP RATED — Indian movies only
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getTopRated() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/top_rated',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // TRENDING — filter Indian movies
  // Weekly trending then filter
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getTrending() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/trending/movie/week',
        params: _baseParams,
        cacheDuration: const Duration(hours: 1),
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // MOVIES BY LANGUAGE
  // Uses discover API with language filter
  // vote_count.gte=50 removes spam/unreleased
  // sort_by=popularity.desc for best results
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getMoviesByLanguage(String langCode) async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/discover/movie',
        params: {
          ..._baseParams,
          'with_original_language': langCode,
          'sort_by': 'popularity.desc',
          'vote_count.gte': 50,
          'page': 1,
        },
        cacheDuration: const Duration(hours: 2),
      );
      final results = data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      searchMovies(String query) async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/search/movie',
        params: {
          ..._baseParams,
          'query': query,
          'page': 1,
        },
        cacheDuration: const Duration(minutes: 10),
      );
      final results = data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // MOVIE DETAILS COMPLETE
  // Single API call with append_to_response
  // ═══════════════════════════════════
  Future<Map<String, dynamic>?>
      getMovieDetailsComplete(int movieId) async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/$movieId',
        params: {
          ..._baseParams,
          'append_to_response':
              'credits,videos,similar,release_dates',
        },
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      debugPrint(
        'getMovieDetailsComplete error: $e',
      );
      return null;
    }
  }

  // Parse helpers — no extra API calls
  List<Map<String, dynamic>> parseCast(
    Map<String, dynamic>? complete,
  ) {
    try {
      if (complete == null) return [];
      final credits =
          complete['credits'] as Map<String, dynamic>?;
      if (credits == null) return [];
      final cast = credits['cast'] as List? ?? [];
      return cast
          .take(10)
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  String? parseTrailer(
    Map<String, dynamic>? complete,
  ) {
    try {
      if (complete == null) return null;
      final videos =
          complete['videos'] as Map<String, dynamic>?;
      if (videos == null) return null;
      final results = videos['results'] as List? ?? [];
      final trailer = results.firstWhere(
        (v) =>
            v['type'] == 'Trailer' &&
            v['site'] == 'YouTube',
        orElse: () => null,
      );
      return trailer != null
          ? trailer['key'] as String
          : null;
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> parseSimilar(
    Map<String, dynamic>? complete,
  ) {
    try {
      if (complete == null) return [];
      final similar =
          complete['similar'] as Map<String, dynamic>?;
      if (similar == null) return [];
      final results = similar['results'] as List? ?? [];
      return results
          .take(10)
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Backward compatible methods
  Future<Map<String, dynamic>?> getMovieDetails(
    int movieId,
  ) async =>
      getMovieDetailsComplete(movieId);

  Future<List<Map<String, dynamic>>> getMovieCredits(
    int movieId,
  ) async {
    final complete =
        await getMovieDetailsComplete(movieId);
    return parseCast(complete);
  }

  Future<String?> getMovieTrailer(
    int movieId,
  ) async {
    final complete =
        await getMovieDetailsComplete(movieId);
    return parseTrailer(complete);
  }

  Future<List<Map<String, dynamic>>> getSimilarMovies(
    int movieId,
  ) async {
    final complete =
        await getMovieDetailsComplete(movieId);
    return parseSimilar(complete);
  }

  // ═══════════════════════════════════
  // IS MOVIE NOW PLAYING IN INDIA
  // Uses cached IDs — zero API call
  // ═══════════════════════════════════
  Future<bool> isMovieNowPlayingInIndia(
    int movieId,
  ) async {
    if (_nowPlayingIds.isNotEmpty) {
      return _nowPlayingIds.contains(movieId);
    }
    try {
      await getNowPlaying();
      return _nowPlayingIds.contains(movieId);
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>>
      getRecommendations(int movieId) async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/$movieId/recommendations',
        params: {
          ..._baseParams,
          'page': 1,
        },
      );
      final results = data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // MOVIES BY GENRE
  // ═══════════════════════════════════
  Future<List<Map<String, dynamic>>> getMoviesByGenre(
    int genreId,
  ) async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/discover/movie',
        params: {
          ..._indiaParams,
          'with_genres': genreId,
          'sort_by': 'popularity.desc',
        },
      );
      final results = data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  void clearCache() => _cache.clear();

  String getPosterUrl(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) {
      return '';
    }
    return '$tmdbImageBase$posterPath';
  }

  String getBackdropUrl(String? backdropPath) {
    if (backdropPath == null ||
        backdropPath.isEmpty) {
      return '';
    }
    return '$tmdbImageOriginal$backdropPath';
  }
}