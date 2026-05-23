import 'package:flutter/material.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/indian_filter.dart';

class MovieProvider extends ChangeNotifier {
  final TmdbService _tmdbService = TmdbService();

  // Main movie lists — Indian filtered
  List<TmdbMovie> _nowPlaying = [];
  List<TmdbMovie> _upcoming = [];
  List<TmdbMovie> _popular = [];
  List<TmdbMovie> _trending = [];

  // Language movies cache
  // key: language code, value: movie list
  final Map<String, List<TmdbMovie>> _languageCache =
      {};

  // Loading state per language tab
  final Map<String, bool> _languageLoading = {};

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isLoadingInProgress = false;
  String? _error;

  // Selected language tab
  String _selectedLanguage = 'hi';

  List<TmdbMovie> get nowPlaying => _nowPlaying;
  List<TmdbMovie> get upcoming => _upcoming;
  List<TmdbMovie> get popular => _popular;
  List<TmdbMovie> get trending => _trending;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  String get selectedLanguage => _selectedLanguage;

  bool get hasData =>
      _nowPlaying.isNotEmpty ||
      _upcoming.isNotEmpty ||
      _popular.isNotEmpty ||
      _trending.isNotEmpty;

  // Get movies for selected language tab
  List<TmdbMovie> getLanguageMovies(String lang) =>
      _languageCache[lang] ?? [];

  // Check if language tab is loading
  bool isLanguageLoading(String lang) =>
      _languageLoading[lang] ?? false;

  // ═══════════════════════════════════
  // LOAD ALL MOVIES
  // Preloads Hi/Ta/Te with main content
  // Others load on demand
  // ═══════════════════════════════════
  Future<void> loadAllMovies() async {
    if (_hasLoaded || _isLoadingInProgress) return;

    _isLoadingInProgress = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // All main + preload languages in parallel
      final results = await Future.wait([
        _tmdbService.getNowPlaying(),
        _tmdbService.getUpcoming(),
        _tmdbService.getPopular(),
        _tmdbService.getTrending(),
        // Preload top 3 languages simultaneously
        _tmdbService.getMoviesByLanguage('hi'),
        _tmdbService.getMoviesByLanguage('ta'),
        _tmdbService.getMoviesByLanguage('te'),
      ]);

      _nowPlaying = results[0]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
      _upcoming = results[1]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
      _popular = results[2]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
      _trending = results[3]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();

      // Cache preloaded languages
      _languageCache['hi'] = results[4]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
      _languageCache['ta'] = results[5]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
      _languageCache['te'] = results[6]
          .map((m) => TmdbMovie.fromJson(m))
          .toList();

      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('MovieProvider error: $e');
    }

    _isLoading = false;
    _isLoadingInProgress = false;
    notifyListeners();
  }

  // ═══════════════════════════════════
  // LOAD LANGUAGE ON DEMAND
  // Called when user taps a language tab
  // that hasn't been loaded yet
  // ═══════════════════════════════════
  Future<void> loadLanguageMovies(
    String lang,
  ) async {
    // Already cached — return instantly
    if (_languageCache.containsKey(lang)) {
      if (_selectedLanguage != lang) {
        _selectedLanguage = lang;
        notifyListeners();
      }
      return;
    }

    // Mark loading for this language
    _languageLoading[lang] = true;
    _selectedLanguage = lang;
    notifyListeners();

    try {
      final movies =
          await _tmdbService.getMoviesByLanguage(lang);
      _languageCache[lang] = movies
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
    } catch (e) {
      _languageCache[lang] = [];
      debugPrint(
        'Language load error ($lang): $e',
      );
    }

    _languageLoading[lang] = false;
    notifyListeners();
  }

  // Select language tab without loading
  // Used when tab already cached
  void selectLanguage(String lang) {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      notifyListeners();
      // Load if not cached
      if (!_languageCache.containsKey(lang)) {
        loadLanguageMovies(lang);
      }
    }
  }

  Future<void> refresh() async {
    _hasLoaded = false;
    _isLoadingInProgress = false;
    _languageCache.clear();
    _languageLoading.clear();
    _tmdbService.clearCache();
    _nowPlaying = [];
    _upcoming = [];
    _popular = [];
    _trending = [];
    notifyListeners();
    await loadAllMovies();
  }

  void clear() {
    _nowPlaying = [];
    _upcoming = [];
    _popular = [];
    _trending = [];
    _languageCache.clear();
    _languageLoading.clear();
    _hasLoaded = false;
    _isLoadingInProgress = false;
    _error = null;
    notifyListeners();
  }
}