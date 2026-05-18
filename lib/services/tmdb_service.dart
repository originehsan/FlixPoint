import 'package:dio/dio.dart';
import 'package:movieticket/utils/constants.dart';

class TmdbService {
  final Dio _dio = Dio();

  // NOW PLAYING - India region
  Future<List<Map<String, dynamic>>> getNowPlaying() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/now_playing',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'region': 'IN',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // UPCOMING - India region
  Future<List<Map<String, dynamic>>> getUpcoming() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/upcoming',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'region': 'IN',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // POPULAR - India region
  Future<List<Map<String, dynamic>>> getPopular() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/popular',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'region': 'IN',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // TOP RATED
  Future<List<Map<String, dynamic>>> getTopRated() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/top_rated',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'region': 'IN',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // SEARCH
  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/search/movie',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'query': query,
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // MOVIE DETAILS
  Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/$movieId',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
        },
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // MOVIE CREDITS
  Future<List<Map<String, dynamic>>> getMovieCredits(int movieId) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/$movieId/credits',
        queryParameters: {
          'api_key': tmdbApiKey,
        },
      );
      final cast = response.data['cast'] as List;
      return cast.take(10).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // MOVIE TRAILER
  Future<String?> getMovieTrailer(int movieId) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/$movieId/videos',
        queryParameters: {
          'api_key': tmdbApiKey,
        },
      );
      final results = response.data['results'] as List;
      final trailer = results.firstWhere(
        (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
        orElse: () => null,
      );
      return trailer != null ? trailer['key'] as String : null;
    } catch (e) {
      return null;
    }
  }

  // RECOMMENDATIONS based on movie
  Future<List<Map<String, dynamic>>> getRecommendations(int movieId) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/$movieId/recommendations',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // SIMILAR MOVIES
  Future<List<Map<String, dynamic>>> getSimilarMovies(int movieId) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/$movieId/similar',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // CHECK IF MOVIE IS NOW PLAYING IN INDIA
  Future<bool> isMovieNowPlayingInIndia(int movieId) async {
    try {
      int page = 1;
      bool found = false;
      while (page <= 3 && !found) {
        final response = await _dio.get(
          '$tmdbBaseUrl/movie/now_playing',
          queryParameters: {
            'api_key': tmdbApiKey,
            'language': 'en-US',
            'region': 'IN',
            'page': page,
          },
        );
        final results = response.data['results'] as List;
        found = results.any((m) => m['id'] == movieId);
        page++;
      }
      return found;
    } catch (e) {
      return false;
    }
  }

  // TRENDING MOVIES
  Future<List<Map<String, dynamic>>> getTrending() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/trending/movie/week',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // MOVIES BY GENRE
  Future<List<Map<String, dynamic>>> getMoviesByGenre(int genreId) async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/discover/movie',
        queryParameters: {
          'api_key': tmdbApiKey,
          'language': 'en-US',
          'region': 'IN',
          'with_genres': genreId,
          'sort_by': 'popularity.desc',
          'page': 1,
        },
      );
      final results = response.data['results'] as List;
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // IMAGE HELPERS
  String getPosterUrl(String? posterPath) {
    if (posterPath == null) return '';
    return '$tmdbImageBase$posterPath';
  }

  String getBackdropUrl(String? backdropPath) {
    if (backdropPath == null) return '';
    return '$tmdbImageOriginal$backdropPath';
  }
}
