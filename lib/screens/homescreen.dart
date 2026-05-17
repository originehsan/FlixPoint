import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/screens/search_screen.dart';
import 'package:movieticket/screens/startscreen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/coming_soon.dart';
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

  @override
  void initState() {
    super.initState();
    // Load movies if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProvider = Provider.of<MovieProvider>(
        context,
        listen: false,
      );
      if (!movieProvider.hasData) {
        movieProvider.loadAllMovies();
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _navigateToDetails(TmdbMovie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movie: movie),
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
        onRefresh: () => movieProvider.refresh(),
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
                      _buildSearchBar(),
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
                      _buildEventsSection(),
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
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
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
                Icons.search,
                color: appthemecolor,
                size: R.sp(20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const StartScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: errorColor,
                size: R.sp(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
        ),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          R.horizontalPadding, 8,
          R.horizontalPadding, 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: appthemecolor, size: 20),
            const SizedBox(width: 12),
            Text(
              'Search movies, events...',
              style: TextStyle(
                color: hintColor,
                fontSize: R.sp(14),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4,
              ),
              decoration: BoxDecoration(
                color: appthemecolor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Search',
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: R.sp(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
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
            autoPlayAnimationDuration:
                const Duration(milliseconds: 800),
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
                      color: appthemecolor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _tmdbService
                              .getBackdropUrl(movie.backdropPath),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _shimmerBox(
                            double.infinity, double.infinity,
                          ),
                          errorWidget: (context, url, error) =>
                              _errorBox(),
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
                              horizontal: 8, vertical: 4,
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
                              horizontal: 8, vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: appthemecolor
                                    .withValues(alpha: 0.5),
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: appthemecolor
                                              .withValues(alpha: 0.15),
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
                                            fontSize: R.sp(9),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () =>
                                          _navigateToDetails(movie),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
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
        R.horizontalPadding, 20,
        R.horizontalPadding, 10,
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
                  horizontal: 12, vertical: 4,
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
          height: R.sectionHeight,
          child: isLoading
              ? _buildHorizontalShimmer()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: R.horizontalPadding,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return GestureDetector(
                      onTap: () => _navigateToDetails(movie),
                      child: Container(
                        width: R.movieCardWidth,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(R.cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(R.cardRadius),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'movie_${movie.id}_$title',
                                child: CachedNetworkImage(
                                  imageUrl: _tmdbService
                                      .getPosterUrl(movie.posterPath),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(
                                    color: surfaceColor,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: appthemecolor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: surfaceColor,
                                    child: const Icon(
                                      Icons.movie,
                                      color: appthemecolor,
                                    ),
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
                                        Colors.black
                                            .withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            Icons.star,
                                            color: appthemecolor,
                                            size: R.sp(10),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            movie.formattedRating,
                                            style: TextStyle(
                                              color: appthemecolor,
                                              fontSize: R.sp(9),
                                              fontWeight: FontWeight.w600,
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
                          delay: Duration(
                            milliseconds: index * 50,
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
                height: R.comingSoonSectionHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: R.horizontalPadding,
                  ),
                  itemCount: movieProvider.upcoming.length,
                  itemBuilder: (context, index) {
                    return ComingSoon(
                      movie: movieProvider.upcoming[index],
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Live Events'),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildHorizontalShimmer();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.horizontalPadding,
                  vertical: 16,
                ),
                child: Text(
                  'No events available',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(13),
                  ),
                ),
              );
            }
            return SizedBox(
              height: R.sectionHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: R.horizontalPadding,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                  return Container(
                    width: R.movieCardWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(R.cardRadius),
                      border: Border.all(
                        color: appthemecolor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(
                            data['logo'] ?? '',
                          ),
                          backgroundColor: surfaceColor2,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['logoname'] ?? '',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
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