import 'package:flutter/material.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';

class MovieProvider extends ChangeNotifier {
  final TmdbService _tmdbService = TmdbService();

  // Movie lists
  List<TmdbMovie> _nowPlaying = [];
  List<TmdbMovie> _upcoming = [];
  List<TmdbMovie> _popular = [];

  // Loading states
  bool _isLoadingNowPlaying = false;
  bool _isLoadingUpcoming = false;
  bool _isLoadingPopular = false;

  // Error states
  String? _error;

  // Getters
  List<TmdbMovie> get nowPlaying => _nowPlaying;
  List<TmdbMovie> get upcoming => _upcoming;
  List<TmdbMovie> get popular => _popular;
  bool get isLoadingNowPlaying => _isLoadingNowPlaying;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoading =>
      _isLoadingNowPlaying ||
      _isLoadingUpcoming ||
      _isLoadingPopular;
  String? get error => _error;

  // Check if data already loaded
  bool get hasData =>
      _nowPlaying.isNotEmpty ||
      _upcoming.isNotEmpty ||
      _popular.isNotEmpty;

  // Load all movies at once
  Future<void> loadAllMovies() async {
    await Future.wait([
      loadNowPlaying(),
      loadUpcoming(),
      loadPopular(),
    ]);
  }

  // Load now playing movies
  Future<void> loadNowPlaying() async {
    if (_isLoadingNowPlaying) return;
    _isLoadingNowPlaying = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _tmdbService.getNowPlaying();
      _nowPlaying = results
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading now playing: $e');
    }
    _isLoadingNowPlaying = false;
    notifyListeners();
  }

  // Load upcoming movies
  Future<void> loadUpcoming() async {
    if (_isLoadingUpcoming) return;
    _isLoadingUpcoming = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _tmdbService.getUpcoming();
      _upcoming = results
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading upcoming: $e');
    }
    _isLoadingUpcoming = false;
    notifyListeners();
  }

  // Load popular movies
  Future<void> loadPopular() async {
    if (_isLoadingPopular) return;
    _isLoadingPopular = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _tmdbService.getPopular();
      _popular = results
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading popular: $e');
    }
    _isLoadingPopular = false;
    notifyListeners();
  }

  // Refresh all movies
  Future<void> refresh() async {
    _nowPlaying = [];
    _upcoming = [];
    _popular = [];
    notifyListeners();
    await loadAllMovies();
  }

  // Clear all data
  void clear() {
    _nowPlaying = [];
    _upcoming = [];
    _popular = [];
    _error = null;
    notifyListeners();
  }
}