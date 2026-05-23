import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static final SearchHistoryService _instance =
      SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  static const String _key = 'search_history';
  static const int _maxItems = 10;

  // Get all search history
  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  // Add search query
  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    final history = await getHistory();

    // Remove if already exists (move to top)
    history.remove(query.trim());

    // Add to beginning
    history.insert(0, query.trim());

    // Keep only max items
    final trimmed = history.take(_maxItems).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  // Remove single search
  Future<void> removeSearch(String query) async {
    final history = await getHistory();
    history.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history));
  }

  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}