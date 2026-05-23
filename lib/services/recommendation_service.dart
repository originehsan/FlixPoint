import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:movieticket/services/search_history_service.dart';
import 'package:movieticket/services/watchlist_service.dart';
import 'package:movieticket/utils/constants.dart';

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final WatchlistService _watchlistService =
      WatchlistService();
  final SearchHistoryService _historyService =
      SearchHistoryService();

  // Always prefix with bollywood context
  // Prevents GNews 400 errors
  static const Map<int, String> _genreKeywords = {
    28: 'bollywood action',
    35: 'bollywood comedy',
    18: 'bollywood drama',
    27: 'bollywood horror',
    10749: 'bollywood romance',
    878: 'bollywood sci-fi',
    53: 'bollywood thriller',
    80: 'bollywood crime',
    12: 'bollywood adventure',
    16: 'bollywood animation',
    99: 'bollywood documentary',
    14: 'bollywood fantasy',
    10402: 'bollywood music',
    9648: 'bollywood mystery',
    10752: 'bollywood war',
    37: 'bollywood western',
    36: 'bollywood historical',
    10751: 'bollywood family',
  };

  // Safe defaults that always work with GNews
  static const List<String> _defaultQueries = [
    'bollywood',
    'bollywood movies',
    'hindi cinema',
    'bollywood news',
  ];

  Future<List<String>> getPersonalizedQueries() async {
    final queries = <String>{};
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      debugPrint('👤 No user → using defaults');
      return _defaultQueries;
    }

    try {
      // 1. From watchlist genres
      final watchlist =
          await _watchlistService.getWatchlistOnce();

      final genreIds = watchlist
          .expand((m) => m.genreIds)
          .toSet();

      for (final id in genreIds.take(2)) {
        final keyword = _genreKeywords[id];
        if (keyword != null) {
          queries.add(keyword);
        }
      }

      // 2. From watchlist movie titles
      for (final movie in watchlist.take(1)) {
        final title = movie.title.trim();
        if (title.length > 3) {
          queries.add('$title movie');
        }
      }

      // 3. From booking history
      try {
        final bookings =
            await FirebaseFirestore.instance
                .collection(colBookings)
                .where('userId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .limit(2)
                .get();

        for (final doc in bookings.docs) {
          final data = doc.data();
          final movieName =
              data['movieName'] as String?;
          if (movieName != null &&
              movieName.isNotEmpty) {
            queries.add('$movieName bollywood');
          }
        }
      } catch (_) {
        // Firestore index might not exist
      }

      // 4. From search history
      final searches =
          await _historyService.getHistory();
      for (final s in searches.take(1)) {
        if (s.trim().length > 3) {
          queries.add('$s bollywood');
        }
      }
    } catch (e) {
      debugPrint('Recommendation error: $e');
    }

    // Always ensure bollywood base
    queries.addAll(['bollywood', 'bollywood movies']);

    final result = queries.toSet().take(4).toList();
    debugPrint('📋 Final queries: $result');
    return result.isEmpty ? _defaultQueries : result;
  }
}