import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/screens/search_screen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/movie_card_widget.dart';
import 'package:movieticket/widgets/offline_banner.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class Homescreen extends StatefulWidget {
  final String name;
  const Homescreen({super.key, required this.name});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final TmdbService _tmdbService = TmdbService();
  int _featuredIndex = 0;
  List<TmdbMovie> _recommendations = [];
  bool _isLoadingRecommendations = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProvider = Provider.of<MovieProvider>(
        context,
        listen: false,
      );
      if (!movieProvider.hasData) {
        movieProvider.loadAllMovies();
      }
      _loadRecommendations();
    });
    // Add connectivity listener
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = _isOffline;
      if (mounted) {
        setState(() {
          _isOffline = result.contains(ConnectivityResult.none);
        });
      }
      if (wasOffline && !_isOffline && mounted) {
        Provider.of<MovieProvider>(context, listen: false).refresh();
        _loadRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() => _isLoadingRecommendations = true);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        setState(() => _isLoadingRecommendations = false);
        return;
      }

      // Get last booked movie
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (bookings.docs.isEmpty) {
        setState(() => _isLoadingRecommendations = false);
        return;
      }

      final lastBooking = bookings.docs.first.data();
      final lastMovieId = lastBooking['movieId'];
      if (lastMovieId == null) {
        setState(() => _isLoadingRecommendations = false);
        return;
      }

      final recs = await _tmdbService.getRecommendations(
        lastMovieId is int ? lastMovieId : int.parse('$lastMovieId'),
      );

      if (mounted) {
        setState(() {
          _recommendations = recs.map((m) => TmdbMovie.fromJson(m)).toList();
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildOfflineBanner() {
    if (!_isOffline) return const SizedBox();
    return OfflineBanner(
      onRetry: () async {
        final result = await Connectivity().checkConnectivity();
        if (mounted) {
          setState(() {
            _isOffline = result.contains(ConnectivityResult.none);
          });
          if (!_isOffline) {
            Provider.of<MovieProvider>(
              context,
              listen: false,
            ).refresh();
          }
        }
      },
    );
  }

  void _navigateToDetails(TmdbMovie movie) {
    Navigator.push(
      context,
      AppRoutes.fadeRoute(MovieDetailsScreen(movie: movie)),
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
                  constraints: BoxConstraints(maxWidth: R.maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOfflineBanner(),
                      _buildFeaturedSection(movieProvider),
                      _buildSection(
                        title: 'Now Playing',
                        movies: movieProvider.nowPlaying,
                        isLoading: movieProvider.isLoadingNowPlaying,
                      ),
                      _buildComingSoonSection(movieProvider),
                      _buildSection(
                        title: 'Popular',
                        movies: movieProvider.popular,
                        isLoading: movieProvider.isLoadingPopular,
                      ),
                      _buildRecommendationsSection(),
                      _buildTrendingSection(movieProvider),
                      const SizedBox(height: 20),
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
      toolbarHeight: 70,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}, ${widget.name}',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: R.sp(12),
                  fontWeight: FontWeight.w400,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [appthemecolor, goldLight],
                ).createShader(bounds),
                child: Text(
                  'FlixPoint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: R.sp(24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              AppRoutes.slideRightRoute(const SearchScreen()),
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
                Icons.search,
                color: appthemecolor,
                size: R.sp(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(MovieProvider movieProvider) {
    if (movieProvider.isLoadingNowPlaying) {
      return _buildFeaturedShimmer();
    }
    if (movieProvider.nowPlaying.isEmpty) return const SizedBox();

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
            onPageChanged: (index, reason) {
              setState(() => _featuredIndex = index);
            },
          ),
          items: movieProvider.nowPlaying.take(5).map((movie) {
            return GestureDetector(
              onTap: () => _navigateToDetails(movie),
              child: Hero(
                tag: 'movie_${movie.id}',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
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
                          imageUrl:
                              _tmdbService.getBackdropUrl(movie.backdropPath),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _shimmerBox(
                            double.infinity,
                            double.infinity,
                          ),
                          errorWidget: (context, url, error) => _errorBox(),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: heroGradient,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: appthemecolor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FEATURED',
                              style: TextStyle(
                                color: mobileBackgroundColor,
                                fontSize: R.sp(9),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: appthemecolor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: appthemecolor,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  movie.formattedRating,
                                  style: TextStyle(
                                    color: appthemecolor,
                                    fontSize: R.sp(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: R.sp(16),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
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
                                              color: appthemecolor.withValues(
                                                  alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: appthemecolor.withValues(
                                                    alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              genre,
                                              style: TextStyle(
                                                color: appthemecolor,
                                                fontSize: R.sp(9),
                                              ),
                                            ),
                                          ),
                                        ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _navigateToDetails(movie),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: appthemecolor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Book Now',
                                          style: TextStyle(
                                            color: mobileBackgroundColor,
                                            fontSize: R.sp(10),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            movieProvider.nowPlaying.take(5).length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _featuredIndex == index ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _featuredIndex == index
                    ? appthemecolor
                    : secondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
                boxShadow: _featuredIndex == index
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
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        20,
        R.horizontalPadding,
        10,
      ),
      child: Row(
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
                  blurRadius: 8,
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
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: appthemecolor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: appthemecolor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: appthemecolor,
                    fontSize: R.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<TmdbMovie> movies,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, onSeeAll: () {}),
        SizedBox(
          height: R.movieCardHeight + 60,
          child: isLoading
              ? _buildHorizontalShimmer()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? R.horizontalPadding : 0,
                        right: index == movies.length - 1
                            ? R.horizontalPadding
                            : 12,
                      ),
                      child: MovieCardWidget(
                        movie: movies[index],
                        index: index,
                        onTap: () => _navigateToDetails(movies[index]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComingSoonSection(MovieProvider movieProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Coming Soon', onSeeAll: () {}),
        movieProvider.isLoadingUpcoming
            ? _buildHorizontalShimmer()
            : SizedBox(
                height: R.movieCardHeight + 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: movieProvider.upcoming.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? R.horizontalPadding : 0,
                        right: index == movieProvider.upcoming.length - 1
                            ? R.horizontalPadding
                            : 12,
                      ),
                      child: MovieCardWidget(
                        movie: movieProvider.upcoming[index],
                        index: index,
                        onTap: () =>
                            _navigateToDetails(movieProvider.upcoming[index]),
                        badgeText: 'SOON',
                        badgeColor: appthemecolor,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // NEW: Recommendations Section
  Widget _buildRecommendationsSection() {
    if (_isLoadingRecommendations) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Recommended For You'),
          _buildHorizontalShimmer(),
        ],
      );
    }

    if (_recommendations.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recommended For You'),
        SizedBox(
          height: R.movieCardHeight + 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final movie = _recommendations[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? R.horizontalPadding : 0,
                  right: index == _recommendations.length - 1
                      ? R.horizontalPadding
                      : 12,
                ),
                child: MovieCardWidget(
                  movie: movie,
                  index: index,
                  onTap: () => _navigateToDetails(movie),
                  badgeText: 'FOR YOU',
                  badgeColor: const Color(0xFF6D28D9),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(MovieProvider movieProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Trending Today'),
        movieProvider.isLoadingTrending
            ? _buildHorizontalShimmer()
            : movieProvider.trending.isEmpty
                ? const SizedBox()
                : SizedBox(
                    height: R.movieCardHeight + 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: movieProvider.trending.length,
                      itemBuilder: (context, index) {
                        final movie = movieProvider.trending[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? R.horizontalPadding : 0,
                            right: index == movieProvider.trending.length - 1
                                ? R.horizontalPadding
                                : 12,
                          ),
                          child: MovieCardWidget(
                            movie: movie,
                            index: index,
                            onTap: () => _navigateToDetails(movie),
                            badgeText: 'HOT',
                            badgeColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildFeaturedShimmer() {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: surfaceColor2,
      child: Container(
        height: R.featuredHeight,
        margin: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
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
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: surfaceColor,
          highlightColor: surfaceColor2,
          child: Container(
            width: R.movieCardWidth,
            height: R.sectionHeight,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(R.cardRadius),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: surfaceColor2,
      child: Container(
        width: width,
        height: height,
        color: surfaceColor,
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      color: surfaceColor,
      child: const Center(
        child: Icon(Icons.movie, color: appthemecolor, size: 30),
      ),
    );
  }
}
