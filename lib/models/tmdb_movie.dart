class TmdbMovie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;
  final String? originalLanguage;
  // BUG 24 fix: store genre objects
  // from detail API response
  final List<Map<String, dynamic>> genreObjects;

  TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    this.originalLanguage,
    this.genreObjects = const [],
  });

  factory TmdbMovie.fromJson(
    Map<String, dynamic> json,
  ) {
    // BUG 24 fix: parse genres from both
    // list API (integer array) and
    // detail API (object array)
    List<int> ids = [];
    List<Map<String, dynamic>> objects = [];

    final rawGenres = json['genres'];
    final rawGenreIds = json['genre_ids'];

    if (rawGenres != null) {
      // Detail API format:
      // [{id: 28, name: 'Action'}]
      objects = List<Map<String, dynamic>>.from(
        (rawGenres as List).map(
          (g) => Map<String, dynamic>.from(g),
        ),
      );
      ids = objects
          .map((g) => g['id'] as int)
          .toList();
    } else if (rawGenreIds != null) {
      // List API format: [28, 12]
      ids = List<int>.from(rawGenreIds);
    }

    return TmdbMovie(
      id: json['id'] ?? 0,
      // BUG 42 fix: fallback title
      title: (json['title'] as String?)
              ?.isNotEmpty == true
          ? json['title']
          : 'Unknown Title',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage:
          (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? '',
      genreIds: ids,
      originalLanguage: json['original_language'],
      genreObjects: objects,
    );
  }

  static const Map<int, String> genreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  List<String> get genreNames {
    // BUG 24 fix: use genre objects
    // from detail API if available
    if (genreObjects.isNotEmpty) {
      return genreObjects
          .map((g) => g['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .take(2)
          .toList();
    }
    // Fall back to genre map for list API
    return genreIds
        .map((id) => genreMap[id] ?? '')
        .where((name) => name.isNotEmpty)
        .take(2)
        .toList();
  }

  String get formattedRating {
    return voteAverage.toStringAsFixed(1);
  }

  String get year {
    if (releaseDate.isEmpty) return '';
    if (releaseDate.length < 4) return '';
    return releaseDate.substring(0, 4);
  }
}