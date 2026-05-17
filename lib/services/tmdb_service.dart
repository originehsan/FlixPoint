import 'package:dio/dio.dart';
import 'package:movieticket/utils/constants.dart';

class TmdbService {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> getNowPlaying() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/now_playing',
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

  Future<List<Map<String, dynamic>>> getUpcoming() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/upcoming',
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

  Future<List<Map<String, dynamic>>> getPopular() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/popular',
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

  Future<List<Map<String, dynamic>>> getTopRated() async {
    try {
      final response = await _dio.get(
        '$tmdbBaseUrl/movie/top_rated',
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

  String getPosterUrl(String? posterPath) {
    if (posterPath == null) return '';
    return '$tmdbImageBase$posterPath';
  }

  String getBackdropUrl(String? backdropPath) {
    if (backdropPath == null) return '';
    return '$tmdbImageOriginal$backdropPath';
  }
}