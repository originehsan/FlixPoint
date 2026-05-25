import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/screens/search_screen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/indian_filter.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/loaders/app_loader.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/movie/movie_card_widget.dart';
import 'package:movieticket/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  final String name;
  const Homescreen({
    super.key,
    required this.name,
  });

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final TmdbService _tmdbService = TmdbService();

  // BUG 35 fix: ValueNotifier prevents
  // full homescreen rebuild on carousel change
  final ValueNotifier<int> _featuredIndex = ValueNotifier(0);

  List<TmdbMovie> _recommendations = [];
  bool _isLoadingRecommendations = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadRecommendations(),
    );
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = _isOffline;
      if (mounted) {
        setState(() {
          _isOffline = result.contains(
            ConnectivityResult.none,
          );
        });
      }
      if (wasOffline && !_isOffline && mounted) {
        Provider.of<MovieProvider>(
          context,
          listen: false,
        ).refresh();
        _loadRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _featuredIndex.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(
        () => _isLoadingRecommendations = true,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        setState(
          () => _isLoadingRecommendations = false,
        );
        return;
      }

      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      if (bookings.docs.isEmpty) {
        setState(
          () => _isLoadingRecommendations = false,
        );
        return;
      }

      // BUG 28 fix: try multiple recent bookings
      // not just the last one
      final List<TmdbMovie> allRecs = [];
      for (final doc in bookings.docs) {
        final data = doc.data();
        final movieId = data['movieId'];
        if (movieId == null) continue;

        final recs = await _tmdbService.getRecommendations(
          movieId is int ? movieId : int.parse('$movieId'),
        );
        allRecs.addAll(
          recs.map((m) => TmdbMovie.fromJson(m)).toList(),
        );
        if (allRecs.length >= 10) break;
      }

      if (mounted) {
        setState(() {
          // Remove duplicates by id
          final seen = <int>{};
          _recommendations = allRecs.where((m) => seen.add(m.id)).toList();
          _isLoadingRecommendations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _isLoadingRecommendations = false,
        );
      }
    }
  }

  // Time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Time-based emoji
  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 17) return '☀️';
    return '🌙';
  }

  // Time-based subtitle
  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Ready for a movie today?';
    if (hour < 17) return 'What will you watch?';
    if (hour < 20) return 'Perfect time for a movie!';
    return 'Enjoy tonight\'s show!';
  }

  void _navigateToDetails(
    TmdbMovie movie,
    String section,
  ) {
    Navigator.push(
      context,
      AppRoutes.scaleRoute(
        MovieDetailsScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final movieProvider = Provider.of<MovieProvider>(context);

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: RefreshIndicator(
        color: appthemecolor,
        backgroundColor: surfaceColor,
        onRefresh: () async {
          await movieProvider.refresh();
          await _loadRecommendations();
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: R.maxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isOffline)
                        OfflineBanner(
                          onRetry: () async {
                            final result =
                                await Connectivity().checkConnectivity();
                            if (mounted) {
                              setState(() {
                                _isOffline = result.contains(
                                  ConnectivityResult.none,
                                );
                              });
                              if (!_isOffline) {
                                Provider.of<MovieProvider>(
                                  context,
                                  listen: false,
                                ).refresh();
                              }
                            }
                          },
                        ),
                      _buildFeaturedSection(
                        movieProvider,
                      ),
                      _buildMovieSection(
                        title: 'Now Playing',
                        movies: movieProvider.nowPlaying,
                        isLoading: movieProvider.isLoading,
                        section: 'nowplaying',
                      ),
                      _buildMovieSection(
                        title: 'Coming Soon',
                        movies: movieProvider.upcoming,
                        isLoading: movieProvider.isLoading,
                        badgeText: 'SOON',
                        badgeColor: appthemecolor,
                        section: 'upcoming',
                      ),
                      _buildIndianCinemaSection(
                        movieProvider,
                      ),
                      _buildMovieSection(
                        title: 'Popular',
                        movies: movieProvider.popular,
                        isLoading: movieProvider.isLoading,
                        section: 'popular',
                      ),
                      _buildMovieSection(
                        title: 'Recommended For You',
                        movies: _recommendations,
                        isLoading: _isLoadingRecommendations,
                        badgeText: 'FOR YOU',
                        badgeColor: const Color(0xFF6D28D9),
                        hideIfEmpty: true,
                        section: 'recommended',
                      ),
                      _buildMovieSection(
                        title: 'Trending Today',
                        movies: movieProvider.trending,
                        isLoading: movieProvider.isLoading,
                        badgeText: 'HOT',
                        badgeColor: errorColor,
                        hideIfEmpty: true,
                        section: 'trending',
                      ),
                      const Gap(20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: mobileBackgroundColor,
      floating: true,
      snap: true,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting with emoji
                Row(
                  children: [
                    Text(
                      _getGreetingEmoji(),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: R.sp(12),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                // Name with gold accent
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      primaryColor,
                      appthemecolor,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    widget.name.isEmpty ? 'FlixPoint' : widget.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: R.sp(20),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Subtitle based on time
                Text(
                  _getGreetingSubtitle(),
                  style: TextStyle(
                    color: secondaryColor.withValues(alpha: 0.6),
                    fontSize: R.sp(11),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Search button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              AppRoutes.slideRightRoute(
                const SearchScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                color: appthemecolor,
                size: R.sp(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(
    MovieProvider movieProvider,
  ) {
    if (movieProvider.isLoading) {
      return ShimmerBox(
        width: double.infinity,
        height: R.featuredHeight,
        borderRadius: 16,
        margin: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
      );
    }
    if (movieProvider.nowPlaying.isEmpty) {
      return const SizedBox();
    }

    final featured = movieProvider.nowPlaying.take(5).toList();

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: R.featuredHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            enlargeFactor: 0.15,
            viewportFraction: 0.85,
            onPageChanged: (index, _) {
              // BUG 35 fix: ValueNotifier
              // only rebuilds dot indicators
              _featuredIndex.value = index;
            },
          ),
          items: featured
              .map(
                (movie) => _FeaturedCard(
                  movie: movie,
                  tmdbService: _tmdbService,
                  onTap: () => _navigateToDetails(
                    movie,
                    'featured',
                  ),
                ),
              )
              .toList(),
        ),
        const Gap(10),
        // ValueListenableBuilder rebuilds
        // ONLY dot indicators not whole screen
        ValueListenableBuilder<int>(
          valueListenable: _featuredIndex,
          builder: (_, index, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              featured.length,
              (i) => AnimatedContainer(
                duration: const Duration(
                  milliseconds: 400,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                width: index == i ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == i
                      ? appthemecolor
                      : secondaryColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: index == i
                      ? [
                          BoxShadow(
                            color: appthemecolor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildMovieSection({
    required String title,
    required List<TmdbMovie> movies,
    required bool isLoading,
    required String section,
    String? badgeText,
    Color? badgeColor,
    bool hideIfEmpty = false,
  }) {
    if (!isLoading && movies.isEmpty && hideIfEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onSeeAll: () {},
        ),
        SizedBox(
          height: R.movieCardHeight + 60,
          child: isLoading
              ? _buildHorizontalShimmer()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: movies.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? R.horizontalPadding : 0,
                      right:
                          index == movies.length - 1 ? R.horizontalPadding : 12,
                    ),
                    child: MovieCardWidget(
                      movie: movies[index],
                      index: index,
                      onTap: () => _navigateToDetails(
                        movies[index],
                        section,
                      ),
                      badgeText: badgeText,
                      badgeColor: badgeColor,
                      // BUG 29 fix: section in tag
                      heroSection: section,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIndianCinemaSection(
    MovieProvider movieProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Indian Cinema',
          subtitle: 'Select language',
          onSeeAll: null,
        ),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            itemCount: indianLanguages.length,
            itemBuilder: (context, index) {
              final lang = indianLanguages[index];
              final isSelected = movieProvider.selectedLanguage == lang;
              final color = languageColor(lang);

              return GestureDetector(
                onTap: () => movieProvider.selectLanguage(lang),
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 300,
                  ),
                  margin: const EdgeInsets.only(
                    right: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : color.withValues(
                              alpha: 0.4,
                            ),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        languageName(lang),
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontSize: R.sp(11),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (movieProvider.isLanguageLoading(lang)) ...[
                        const Gap(6),
                        AppLoader.small(
                          color: isSelected ? Colors.white : color,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Gap(12),
        SizedBox(
          height: R.movieCardHeight + 60,
          child: movieProvider.isLanguageLoading(
            movieProvider.selectedLanguage,
          )
              ? _buildHorizontalShimmer()
              : movieProvider
                      .getLanguageMovies(
                        movieProvider.selectedLanguage,
                      )
                      .isEmpty
                  ? const SizedBox()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: movieProvider
                          .getLanguageMovies(
                            movieProvider.selectedLanguage,
                          )
                          .length,
                      itemBuilder: (context, index) {
                        final movies = movieProvider.getLanguageMovies(
                          movieProvider.selectedLanguage,
                        );
                        final movie = movies[index];
                        final color = languageColor(
                          movieProvider.selectedLanguage,
                        );
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? R.horizontalPadding : 0,
                            right: index == movies.length - 1
                                ? R.horizontalPadding
                                : 12,
                          ),
                          child: MovieCardWidget(
                            movie: movie,
                            index: index,
                            onTap: () => _navigateToDetails(
                              movie,
                              'indian',
                            ),
                            badgeText: languageName(
                              movieProvider.selectedLanguage,
                            ),
                            badgeColor: color,
                            heroSection: 'indian_'
                                '$index',
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHorizontalShimmer() {
    return SizedBox(
      height: R.sectionHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        itemCount: 5,
        itemBuilder: (_, index) => ShimmerBox(
          width: R.movieCardWidth,
          height: R.sectionHeight,
          borderRadius: R.cardRadius,
          margin: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
        ),
      ),
    );
  }
}

// Featured card
class _FeaturedCard extends StatelessWidget {
  final TmdbMovie movie;
  final TmdbService tmdbService;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.movie,
    required this.tmdbService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    // BUG 29 fix: featured Hero tag is unique
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'movie_${movie.id}_featured',
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appthemecolor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: appthemecolor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: tmdbService.getBackdropUrl(
                    movie.backdropPath,
                  ),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: surfaceColor,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: surfaceColor,
                    child: const Center(
                      child: Icon(
                        Icons.movie,
                        color: appthemecolor,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: heroGradient,
                  ),
                ),
                // Language badge
                if (isIndianMovie({
                  'original_language': movie.originalLanguage,
                }))
                  Positioned(
                    top: 12,
                    left: 12,
                    child: AppBadge(
                      label: languageName(
                        movie.originalLanguage ?? '',
                      ),
                      color: languageColor(
                        movie.originalLanguage ?? '',
                      ),
                      hasGlow: true,
                    ),
                  ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: AppBadge(
                    label: movie.formattedRating,
                    icon: Icons.star_rounded,
                    color: Colors.black.withValues(alpha: 0.6),
                    hasGlow: false,
                  ),
                ),
                // Bottom content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      20,
                      12,
                      12,
                    ),
                    child: Row(
                      children: [
                        ...movie.genreNames.take(2).map(
                              (genre) => Container(
                                margin: const EdgeInsets.only(
                                  right: 6,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: R.sp(9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
