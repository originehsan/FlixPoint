import 'package:dio/dio.dart';
import 'package:movieticket/services/cache_service.dart';
import 'package:movieticket/services/network_service.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/indian_filter.dart';

class TmdbService {
  static final TmdbService _instance = TmdbService._internal();
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

  Future<dynamic> _cachedGet(
    String url, {
    Map<String, dynamic>? params,
    Duration cacheDuration = const Duration(minutes: 30),
  }) async {
    final cacheKey = '$url${params?.toString() ?? ''}';

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

  Future<List<Map<String, dynamic>>> getNowPlaying() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/now_playing',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      final movies = results.cast<Map<String, dynamic>>();
      _nowPlayingIds = movies.map((m) => m['id'] as int).toList();
      return filterIndian(movies);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpcoming() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/upcoming',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPopular() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/popular',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopRated() async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/top_rated',
        params: _indiaParams,
      );
      final results = data['results'] as List;
      return filterIndian(
        results.cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTrending() async {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMoviesByLanguage(
      String langCode) async {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
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
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMovieDetailsComplete(int movieId) async {
    try {
      final data = await _cachedGet(
        '$tmdbBaseUrl/movie/$movieId',
        params: {
          ..._baseParams,
          'append_to_response': 'credits,videos,similar,release_dates',
        },
      );
      return data as Map<String, dynamic>;
    } catch (_) {
      // Removed debugPrint
      return null;
    }
  }

  List<Map<String, dynamic>> parseCast(
    Map<String, dynamic>? complete,
  ) {
    try {
      if (complete == null) return [];
      final credits = complete['credits'] as Map<String, dynamic>?;
      if (credits == null) return [];
      final cast = credits['cast'] as List? ?? [];
      return cast.take(10).toList().cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  String? parseTrailer(
    Map<String, dynamic>? complete,
  ) {
    try {
      if (complete == null) return null;
      final videos = complete['videos'] as Map<String, dynamic>?;
      if (videos == null) return null;
      final results = videos['results'] as List? ?? [];
      final trailer = results.firstWhere(
        (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
        orElse: () => null,
      );
      return trailer != null ? trailer['key'] as String : null;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> parseSimilar(
    Map<String, dynamic>? complete,
  ) {
    try {
      if (complete == null) return [];
      final similar = complete['similar'] as Map<String, dynamic>?;
      if (similar == null) return [];
      final results = similar['results'] as List? ?? [];
      return results.take(10).toList().cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMovieDetails(
    int movieId,
  ) async =>
      getMovieDetailsComplete(movieId);

  Future<List<Map<String, dynamic>>> getMovieCredits(int movieId) async {
    final complete = await getMovieDetailsComplete(movieId);
    return parseCast(complete);
  }

  Future<String?> getMovieTrailer(
    int movieId,
  ) async {
    final complete = await getMovieDetailsComplete(movieId);
    return parseTrailer(complete);
  }

  Future<List<Map<String, dynamic>>> getSimilarMovies(int movieId) async {
    final complete = await getMovieDetailsComplete(movieId);
    return parseSimilar(complete);
  }

  Future<bool> isMovieNowPlayingInIndia(
    int movieId,
  ) async {
    if (_nowPlayingIds.isNotEmpty) {
      return _nowPlayingIds.contains(movieId);
    }
    try {
      await getNowPlaying();
      return _nowPlayingIds.contains(movieId);
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations(int movieId) async {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMoviesByGenre(int genreId) async {
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
    } catch (_) {
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
    if (backdropPath == null || backdropPath.isEmpty) {
      return '';
    }
    return '$tmdbImageOriginal$backdropPath';
  }
}
