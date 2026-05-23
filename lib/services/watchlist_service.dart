import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieticket/models/tmdb_movie.dart';

class WatchlistService {
  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference get _watchlistRef =>
      _firestore.collection('Users').doc(_uid).collection('watchlist');

  Stream<List<TmdbMovie>> getWatchlistStream() {
    if (_uid.isEmpty) return Stream.value([]);
    return _watchlistRef
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return TmdbMovie(
                id: data['movieId'] as int? ?? 0,
                title: data['title'] as String? ?? '',
                posterPath: data['posterPath'] as String?,
                backdropPath: data['backdropPath'] as String?,
                voteAverage: (data['voteAverage'] as num? ?? 0).toDouble(),
                releaseDate: data['releaseDate'] as String? ?? '',
                overview: data['overview'] as String? ?? '',
                genreIds: List<int>.from(
                  data['genreIds'] as List? ?? [],
                ),
              );
            }).toList());
  }

  Future<bool> isInWatchlist(int movieId) async {
    if (_uid.isEmpty) return false;
    try {
      final snap = await _watchlistRef
          .where('movieId', isEqualTo: movieId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleWatchlist(TmdbMovie movie) async {
    if (_uid.isEmpty) return false;
    try {
      final isIn = await isInWatchlist(movie.id);
      if (isIn) {
        await _watchlistRef
            .where('movieId', isEqualTo: movie.id)
            .get()
            .then((snap) {
          for (var doc in snap.docs) {
            doc.reference.delete();
          }
        });
        return false;
      } else {
        await _watchlistRef.add({
          'movieId': movie.id,
          'title': movie.title,
          'posterPath': movie.posterPath,
          'backdropPath': movie.backdropPath,
          'voteAverage': movie.voteAverage,
          'releaseDate': movie.releaseDate,
          'overview': movie.overview,
          'genreIds': movie.genreIds,
          'addedAt': DateTime.now(),
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> removeFromWatchlist(int movieId) async {
    if (_uid.isEmpty) return;
    try {
      final snap =
          await _watchlistRef.where('movieId', isEqualTo: movieId).get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } 
     catch (e) {
    rethrow; // let watchlist_button handle error
  }
  }

  Future<void> clearWatchlist() async {
    if (_uid.isEmpty) return;
    try {
      final snap = await _watchlistRef.get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Add this method before the closing brace:
Future<void> addToWatchlist(TmdbMovie movie) async {
  if (_uid.isEmpty) return;
  try {
    final isIn = await isInWatchlist(movie.id);
    if (isIn) return; // already saved
    await _watchlistRef.add({
      'movieId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'backdropPath': movie.backdropPath,
      'voteAverage': movie.voteAverage,
      'releaseDate': movie.releaseDate,
      'overview': movie.overview,
      'genreIds': movie.genreIds,
      'addedAt': DateTime.now(),
    });
  } catch (e) {
    rethrow; // let watchlist_button handle error
  }
}

  Future<List<TmdbMovie>> getWatchlistOnce() async {
    if (_uid.isEmpty) return [];
    try {
      final snap =
          await _watchlistRef.orderBy('addedAt', descending: true).get();
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TmdbMovie(
          id: data['movieId'] as int? ?? 0,
          title: data['title'] as String? ?? '',
          posterPath: data['posterPath'] as String?,
          backdropPath: data['backdropPath'] as String?,
          voteAverage: (data['voteAverage'] as num? ?? 0).toDouble(),
          releaseDate: data['releaseDate'] as String? ?? '',
          overview: data['overview'] as String? ?? '',
          genreIds: List<int>.from(
            data['genreIds'] as List? ?? [],
          ),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
} // ← closing brace of WatchlistService
