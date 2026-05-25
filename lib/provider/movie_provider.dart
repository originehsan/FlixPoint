import 'package:flutter/material.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';

class MovieProvider extends ChangeNotifier {
  final TmdbService _tmdbService = TmdbService();

  List<TmdbMovie> _nowPlaying = [];
  List<TmdbMovie> _upcoming = [];
  List<TmdbMovie> _popular = [];
  List<TmdbMovie> _trending = [];

  final Map<String, List<TmdbMovie>>
      _languageCache = {};
  final Map<String, bool> _languageLoading = {};

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isLoadingInProgress = false;
  String? _error;
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

  List<TmdbMovie> getLanguageMovies(String lang) =>
      _languageCache[lang] ?? [];

  bool isLanguageLoading(String lang) =>
      _languageLoading[lang] ?? false;

  Future<void> loadAllMovies() async {
    // BUG 6 fix: double guard prevents
    // duplicate parallel calls
    if (_hasLoaded || _isLoadingInProgress) return;

    _isLoadingInProgress = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _tmdbService.getNowPlaying(),
        _tmdbService.getUpcoming(),
        _tmdbService.getPopular(),
        _tmdbService.getTrending(),
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
    }

    _isLoading = false;
    _isLoadingInProgress = false;
    notifyListeners();
  }

  Future<void> loadLanguageMovies(
    String lang,
  ) async {
    if (_languageCache.containsKey(lang)) {
      if (_selectedLanguage != lang) {
        _selectedLanguage = lang;
        notifyListeners();
      }
      return;
    }

    _languageLoading[lang] = true;
    _selectedLanguage = lang;
    notifyListeners();

    try {
      final movies =
          await _tmdbService.getMoviesByLanguage(
        lang,
      );
      _languageCache[lang] = movies
          .map((m) => TmdbMovie.fromJson(m))
          .toList();
    } catch (_) {
      _languageCache[lang] = [];
    }

    _languageLoading[lang] = false;
    notifyListeners();
  }

  void selectLanguage(String lang) {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      notifyListeners();
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