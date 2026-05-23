import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/cinema_selection_screen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/movie/info_chip_widget.dart';
import 'package:movieticket/widgets/cinema/live_seat_counter.dart';
import 'package:movieticket/widgets/movie/movie_card_widget.dart';
import 'package:movieticket/widgets/cinema/theatre_status_widget.dart';
import 'package:movieticket/widgets/movie/trailer_button.dart';
import 'package:movieticket/widgets/movie/watchlist_button.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movieticket/utils/page_transitions.dart';

class MovieDetailsScreen extends StatefulWidget {
  final TmdbMovie movie;
  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailsScreen> createState() =>
      _MovieDetailsScreenState();
}

class _MovieDetailsScreenState
    extends State<MovieDetailsScreen> {
  final TmdbService _tmdbService = TmdbService();

  Map<String, dynamic>? _movieDetails;
  List<Map<String, dynamic>> _cast = [];
  List<TmdbMovie> _similarMovies = [];
  String? _trailerKey;
  bool _isLoading = true;
  bool _isInTheatres = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  // ═══════════════════════════════════
  // ONE API CALL — parses everything
  // locally from complete response
  // BUG FIX: was 4-5 calls before
  // ═══════════════════════════════════
  Future<void> _loadDetails() async {
    try {
      final complete = await _tmdbService
          .getMovieDetailsComplete(widget.movie.id);

      final isInTheatres = await _tmdbService
          .isMovieNowPlayingInIndia(widget.movie.id);

      if (mounted) {
        setState(() {
          _movieDetails = complete;
          _cast = _tmdbService.parseCast(complete);
          _trailerKey =
              _tmdbService.parseTrailer(complete);
          _similarMovies = _tmdbService
              .parseSimilar(complete)
              .map((m) => TmdbMovie.fromJson(m))
              .take(10)
              .toList();
          _isInTheatres = isInTheatres;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        text:
            '🎬 Check out ${widget.movie.title} on FlixPoint!\n\n'
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
                constraints:
                    BoxConstraints(maxWidth: R.maxWidth),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    InfoChipRow(
                      movie: widget.movie,
                      runtime: _runtime,
                    ),
                    if (_trailerKey != null)
                      TrailerButton(
                        trailerKey: _trailerKey!,
                      ),
                    _buildStoryline(),
                    _buildCast(),
                    if (_similarMovies.isNotEmpty)
                      _buildSimilarMovies(),
                    TheatreStatusWidget(
                      isInTheatres: _isInTheatres,
                      isLoading: _isLoading,
                    ),
                    if (_isInTheatres) ...[
                      LiveSeatCounter(
                        movieId: widget.movie.id,
                      ),
                      _buildBookButton(),
                    ],
                    const Gap(30),
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
              color: mobileBackgroundColor
                  .withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor
                    .withValues(alpha: 0.5),
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
          child: WatchlistButton(
            movie: widget.movie,
            size: 18,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: _shareMovie,
            child: Container(
              decoration: BoxDecoration(
                color: mobileBackgroundColor
                    .withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor
                      .withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: appthemecolor
                        .withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
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
            // Backdrop image
            CachedNetworkImage(
              imageUrl: _tmdbService.getBackdropUrl(
                widget.movie.backdropPath,
              ),
              fit: BoxFit.cover,
              // ✅ ShimmerBox instead of Container
              placeholder: (_, __) => ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
              errorWidget: (_, __, ___) => Container(
                color: surfaceColor,
                child: const Icon(
                  Icons.movie,
                  color: appthemecolor,
                  size: 50,
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    mobileBackgroundColor
                        .withValues(alpha: 0.5),
                    mobileBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Movie info at bottom
            Positioned(
              bottom: 20,
              left: R.horizontalPadding,
              right: R.horizontalPadding,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                  const Gap(8),
                  Row(
                    children: [
                      // Rating badge
                      // ✅ AppBadge instead of Container
                      AppBadge(
                        label: widget.movie
                            .formattedRating,
                        icon: Icons.star_rounded,
                        color: appthemecolor,
                        hasGlow: true,
                      ),
                      const Gap(8),
                      // Runtime badge
                      if (_runtime.isNotEmpty) ...[
                        AppBadge(
                          label: _runtime,
                          icon: Icons.access_time_rounded,
                          color: surfaceColor
                              .withValues(alpha: 0.8),
                          hasGlow: false,
                        ),
                        const Gap(8),
                      ],
                      // Year badge
                      AppBadge(
                        label: widget.movie.year,
                        icon: Icons.calendar_today_rounded,
                        color: surfaceColor
                            .withValues(alpha: 0.8),
                        hasGlow: false,
                      ),
                    ],
                  ),
                  const Gap(8),
                  // Genre chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.movie.genreNames
                        .map(
                          (genre) => Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor
                                  .withValues(alpha: 0.8),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: appthemecolor
                                    .withValues(alpha: 0.4),
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

  Widget _buildStoryline() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  SectionHeader instead of _sectionTitle()
          const SectionHeader(title: 'Storyline'),
          const Gap(10),
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
          const Gap(20),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCast() {
    //  ShimmerBox instead of CircularProgressIndicator
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Cast'),
            const Gap(12),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.only(
                    right: 12,
                  ),
                  child: Column(
                    children: [
                      ShimmerBox(
                        width: 64,
                        height: 64,
                        borderRadius: 32,
                      ),
                      const Gap(6),
                      ShimmerBox(
                        width: 60,
                        height: 10,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(20),
          ],
        ),
      );
    }

    if (_cast.isEmpty) return const SizedBox();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  SectionHeader instead of _sectionTitle()
          const SectionHeader(title: 'Cast'),
          const Gap(12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cast.length,
              itemBuilder: (context, index) {
                final actor = _cast[index];
                final profilePath =
                    actor['profile_path'];
                return SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appthemecolor
                                .withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: surfaceColor,
                          backgroundImage:
                              profilePath != null
                                  ? CachedNetworkImageProvider(
                                      '$tmdbImageBase$profilePath',
                                    )
                                  : null,
                          child: profilePath == null
                              ? const Icon(
                                  Icons.person,
                                  color: appthemecolor,
                                  size: 28,
                                )
                              : null,
                        ),
                      ),
                      const Gap(6),
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
                    ],
                  ),
                ).animate().fadeIn(
                      delay: Duration(
                        milliseconds: index * 50,
                      ),
                    );
              },
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }

  Widget _buildSimilarMovies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SectionHeader instead of _sectionTitle()
        SectionHeader(
          title: 'Similar Movies',
          padding: EdgeInsets.fromLTRB(
            R.horizontalPadding,
            16,
            R.horizontalPadding,
            10,
          ),
        ),
        const Gap(4),
        SizedBox(
          height: R.movieCardHeight + 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similarMovies.length,
            itemBuilder: (context, index) {
              final movie = _similarMovies[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0
                      ? R.horizontalPadding
                      : 0,
                  right:
                      index == _similarMovies.length - 1
                          ? R.horizontalPadding
                          : 12,
                ),
                child: MovieCardWidget(
                  movie: movie,
                  index: index,
                  onTap: () =>
                      Navigator.pushReplacement(
                    context,
                    AppRoutes.scaleRoute(
                      MovieDetailsScreen(movie: movie),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Gap(20),
      ],
    );
  }

  //  AppButton instead of
  // GestureDetector + AnimatedContainer
  // Cinema section removed from here
  // → Now in CinemaSelectionScreen
  Widget _buildBookButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        8,
        R.horizontalPadding,
        30,
      ),
      child: AppButton(
        label: 'Book Tickets Now',
        icon: Icons.confirmation_num_rounded,
        onTap: () => Navigator.push(
          context,
          AppRoutes.slideUpRoute(
            CinemaSelectionScreen(
              movie: widget.movie,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.2,
        );
  }
}