import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/seatselection.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:provider/provider.dart';

class MovieDetailsScreen extends StatefulWidget {
  final TmdbMovie movie;
  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final TmdbService _tmdbService = TmdbService();
  Map<String, dynamic>? _movieDetails;
  List<Map<String, dynamic>> _cast = [];
  List<TmdbMovie> _similarMovies = [];
  String? _trailerKey;
  bool _isLoading = true;
  bool _isInTheatres = false;
  bool _theatreSelected = false;
  String _selectedCinemaId = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final results = await Future.wait([
        _tmdbService.getMovieDetails(widget.movie.id),
        _tmdbService.getMovieCredits(widget.movie.id),
        _tmdbService.getMovieTrailer(widget.movie.id),
        _tmdbService.getSimilarMovies(widget.movie.id),
        _tmdbService.isMovieNowPlayingInIndia(widget.movie.id),
      ]);

      if (mounted) {
        setState(() {
          _movieDetails = results[0] as Map<String, dynamic>?;
          _cast = results[1] as List<Map<String, dynamic>>;
          _trailerKey = results[2] as String?;
          final similarRaw = results[3] as List<Map<String, dynamic>>;
          _similarMovies =
              similarRaw.map((m) => TmdbMovie.fromJson(m)).take(10).toList();
          _isInTheatres = results[4] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _runtime {
    if (_movieDetails == null) return '';
    final runtime = _movieDetails!['runtime'] ?? 0;
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return '${hours}h ${minutes}m';
  }

  void _shareMovie() {
    SharePlus.instance.share(
      ShareParams(
        text: '🎬 Check out ${widget.movie.title} on FlixPoint!\n\n'
            '⭐ Rating: ${widget.movie.formattedRating}/10\n'
            '🎭 Genres: ${widget.movie.genreNames.join(', ')}\n\n'
            '${widget.movie.overview.length > 100 ? '${widget.movie.overview.substring(0, 100)}...' : widget.movie.overview}\n\n'
            'Book your tickets now on FlixPoint! 🍿',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: R.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMovieInfo(),
                    _buildStoryline(),
                    _buildCast(),
                    if (_similarMovies.isNotEmpty) _buildSimilarMovies(),
                    _buildTheatreStatus(),
                    if (_isInTheatres) ...[
                      _buildLiveSeatCounter(),
                      _buildCinemaSection(),
                      _buildBookButton(),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
      ),
      backgroundColor: Colors.transparent,
      pinned: true,
      stretch: true,
      expandedHeight: R.featuredHeight + 120,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: mobileBackgroundColor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: appthemecolor,
              size: 18,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: _shareMovie,
            child: Container(
              decoration: BoxDecoration(
                color: mobileBackgroundColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.share_rounded,
                color: appthemecolor,
                size: 18,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _tmdbService.getBackdropUrl(
                widget.movie.backdropPath,
              ),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: surfaceColor),
              errorWidget: (context, url, error) => Container(
                color: surfaceColor,
                child: const Icon(
                  Icons.movie,
                  color: appthemecolor,
                  size: 50,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    mobileBackgroundColor.withValues(alpha: 0.5),
                    mobileBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: R.horizontalPadding,
              right: R.horizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: R.sp(24),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appthemecolor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.black,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.movie.formattedRating,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: R.sp(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_runtime.isNotEmpty)
                        _infoBadge(Icons.access_time, _runtime),
                      const SizedBox(width: 8),
                      _infoBadge(Icons.calendar_today, widget.movie.year),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.movie.genreNames
                        .map(
                          (genre) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: appthemecolor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: appthemecolor,
                                fontSize: R.sp(10),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: appthemecolor, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: appthemecolor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: appthemecolor.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(18),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          _infoChip(Icons.star_rounded, 'Rating', widget.movie.formattedRating,
              appthemecolor),
          const SizedBox(width: 10),
          if (_runtime.isNotEmpty)
            _infoChip(Icons.access_time_rounded, 'Duration', _runtime,
                secondaryColor),
          const SizedBox(width: 10),
          _infoChip(Icons.calendar_month_rounded, 'Year', widget.movie.year,
              secondaryColor),
          if (_trailerKey != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    'https://www.youtube.com/watch?v=$_trailerKey',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF0000).withValues(alpha: 0.8),
                        const Color(0xFFCC0000),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trailer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.sp(12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _infoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: R.sp(18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryline() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Storyline'),
          const SizedBox(height: 10),
          ReadMoreText(
            widget.movie.overview,
            textAlign: TextAlign.justify,
            trimLines: 4,
            trimCollapsedText: 'Read more',
            trimExpandedText: 'Read less',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(14),
              height: 1.7,
            ),
            moreStyle: TextStyle(
              color: appthemecolor,
              fontWeight: FontWeight.w600,
            ),
            lessStyle: TextStyle(
              color: appthemecolor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCast() {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Cast'),
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(
                color: appthemecolor,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }
    if (_cast.isEmpty) return const SizedBox();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Cast'),
          const SizedBox(height: 12),
          SizedBox(
            height: R.castCardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cast.length,
              itemBuilder: (context, index) {
                final actor = _cast[index];
                final profilePath = actor['profile_path'];
                return Container(
                  width: R.castCardWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appthemecolor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: R.circleAvatarRadius,
                          backgroundColor: surfaceColor,
                          backgroundImage: profilePath != null
                              ? CachedNetworkImageProvider(
                                  '$tmdbImageBase$profilePath',
                                )
                              : null,
                          child: profilePath == null
                              ? Icon(
                                  Icons.person,
                                  color: appthemecolor,
                                  size: R.circleAvatarRadius,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actor['name'] ?? '',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: R.sp(10),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (actor['character'] != null)
                        Text(
                          actor['character'],
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(9),
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 50),
                    );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // NEW: Similar Movies Section
  Widget _buildSimilarMovies() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Similar Movies'),
          const SizedBox(height: 12),
          SizedBox(
            height: R.sectionHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _similarMovies.length,
              itemBuilder: (context, index) {
                final movie = _similarMovies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      AppRoutes.scaleRoute(MovieDetailsScreen(movie: movie)),
                    );
                  },
                  child: Container(
                    width: R.movieCardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(R.cardRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                _tmdbService.getPosterUrl(movie.posterPath),
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: surfaceColor),
                            errorWidget: (context, url, error) => Container(
                              color: surfaceColor,
                              child: const Icon(
                                Icons.movie,
                                color: appthemecolor,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.9),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    movie.title,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: R.sp(10),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: appthemecolor,
                                        size: R.sp(10),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        movie.formattedRating,
                                        style: TextStyle(
                                          color: appthemecolor,
                                          fontSize: R.sp(9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 50),
                    );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // NEW: Theatre status check
  Widget _buildTheatreStatus() {
    if (_isLoading) return const SizedBox();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 8,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isInTheatres
              ? successColor.withValues(alpha: 0.1)
              : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isInTheatres
                ? successColor.withValues(alpha: 0.4)
                : secondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isInTheatres
                    ? successColor.withValues(alpha: 0.15)
                    : surfaceColor2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isInTheatres
                    ? Icons.theaters_rounded
                    : Icons.movie_filter_rounded,
                color: _isInTheatres ? successColor : secondaryColor,
                size: R.sp(20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isInTheatres
                        ? 'Now Playing in Theatres'
                        : 'Not Currently in Theatres',
                    style: TextStyle(
                      color: _isInTheatres ? successColor : secondaryColor,
                      fontSize: R.sp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _isInTheatres
                        ? 'Book your tickets now!'
                        : 'This movie is not playing in Indian theatres',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // NEW: Live seat counter
  Widget _buildLiveSeatCounter() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 8,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(colTimings).snapshots(),
        builder: (context, snapshot) {
          int totalBooked = 0;
          const totalSeats = 108; // 4*9 + 3*9 + 5*9 = 108

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              // Only count docs for this movie
              if (doc.id.startsWith('${widget.movie.id}_')) {
                final data = doc.data() as Map<String, dynamic>;
                final booked = List<String>.from(data['booked'] ?? []);
                totalBooked += booked.length;
              }
            }
          }

          final available = totalSeats - totalBooked;
          final percentage = available / totalSeats;

          Color seatColor;
          String seatText;
          if (available > 60) {
            seatColor = successColor;
            seatText = 'Good availability';
          } else if (available > 20) {
            seatColor = warningColor;
            seatText = 'Filling fast!';
          } else {
            seatColor = errorColor;
            seatText = 'Almost full!';
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seatColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      color: seatColor,
                      size: R.sp(18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$available seats available today',
                      style: TextStyle(
                        color: seatColor,
                        fontSize: R.sp(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: seatColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: seatColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        seatText,
                        style: TextStyle(
                          color: seatColor,
                          fontSize: R.sp(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: seatColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(seatColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalBooked of $totalSeats seats booked',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCinemaSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Select Cinema'),
          const SizedBox(height: 12),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('cinema').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: appthemecolor,
                    strokeWidth: 2,
                  ),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: secondaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No cinemas available',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final cinema =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final cinemaId = snapshot.data!.docs[index].id;
                  final isSelected = _selectedCinemaId == cinemaId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCinemaId = cinemaId;
                        _theatreSelected = true;
                      });
                      final bookingProvider = Provider.of<BookingProvider>(
                        context,
                        listen: false,
                      );
                      bookingProvider.setCinema(
                        cinemaId: cinemaId,
                        cinemaName: cinema['name'] ?? '',
                        cinemaAddress: cinema['address'] ?? '',
                        cinemaLogo: cinema['logo'] ?? '',
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? appthemecolor.withValues(alpha: 0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? appthemecolor
                              : appthemecolor.withValues(alpha: 0.15),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: appthemecolor.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: cinema['logo'] ?? '',
                              height: 45,
                              width: 60,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Container(
                                height: 45,
                                width: 60,
                                color: surfaceColor2,
                                child: const Icon(
                                  Icons.movie,
                                  color: appthemecolor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cinema['name'] ?? '',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: R.sp(14),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: appthemecolor,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        cinema['address'] ?? '',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: R.sp(11),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (cinema['distance'] != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_walk,
                                        color: successColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${cinema['distance']} km away',
                                        style: TextStyle(
                                          color: successColor,
                                          fontSize: R.sp(10),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: appthemecolor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: mobileBackgroundColor,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: index * 100),
                      );
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        0,
        R.horizontalPadding,
        30,
      ),
      child: GestureDetector(
        onTap: () {
          if (_theatreSelected) {
            final bookingProvider = Provider.of<BookingProvider>(
              context,
              listen: false,
            );
            bookingProvider.setMovie(widget.movie);
            Navigator.push(
              context,
              AppRoutes.slideUpRoute(SeatSelection(
                movie: widget.movie,
                theatreName: bookingProvider.cinemaName,
                theatreAddress: bookingProvider.cinemaAddress,
                theatreLogo: bookingProvider.cinemaLogo,
                cinemaId: bookingProvider.cinemaId,
              )),
            );
          } else {
            showSnackBar('Please select a cinema first', context);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _theatreSelected
                ? const LinearGradient(
                    colors: [appthemecolor, goldDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _theatreSelected ? null : surfaceColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: appthemecolor, width: 1.5),
            boxShadow: _theatreSelected
                ? [
                    BoxShadow(
                      color: appthemecolor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_num_rounded,
                color: _theatreSelected ? mobileBackgroundColor : appthemecolor,
                size: R.sp(22),
              ),
              const SizedBox(width: 10),
              Text(
                _theatreSelected ? 'Book Tickets Now' : 'Select a Cinema First',
                style: TextStyle(
                  color:
                      _theatreSelected ? mobileBackgroundColor : appthemecolor,
                  fontSize: R.sp(16),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }
}
