import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/screens/search_screen.dart';
import 'package:movieticket/screens/startscreen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/coming_soon.dart';
import 'package:shimmer/shimmer.dart';

class Homescreen extends StatefulWidget {
  final String name;
  const Homescreen({super.key, required this.name});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final TmdbService _tmdbService = TmdbService();
  List<TmdbMovie> _nowPlaying = [];
  List<TmdbMovie> _upcoming = [];
  List<TmdbMovie> _popular = [];
  bool _isLoading = true;
  int _featuredIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final nowPlaying = await _tmdbService.getNowPlaying();
      final upcoming = await _tmdbService.getUpcoming();
      final popular = await _tmdbService.getPopular();
      if (mounted) {
        setState(() {
          _nowPlaying = nowPlaying.map((m) => TmdbMovie.fromJson(m)).toList();
          _upcoming = upcoming.map((m) => TmdbMovie.fromJson(m)).toList();
          _popular = popular.map((m) => TmdbMovie.fromJson(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: RefreshIndicator(
        color: appthemecolor,
        backgroundColor: surfaceColor,
        onRefresh: _loadMovies,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  _buildFeaturedSection(),
                  _buildSection(
                    title: 'Now Playing',
                    movies: _nowPlaying,
                    isLoading: _isLoading,
                  ),
                  _buildComingSoonSection(),
                  _buildSection(
                    title: 'Popular',
                    movies: _popular,
                    isLoading: _isLoading,
                  ),
                  _buildEventsSection(),
                  const SizedBox(height: 20),
                ],
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
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${widget.name}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: secondaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'FlixPoint',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: appthemecolor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.search, color: appthemecolor),
        ),
        IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const StartScreen(),
              ),
            );
          },
          icon: const Icon(Icons.logout, color: secondaryColor),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: secondaryColor, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search movies, events...',
              style: TextStyle(color: hintColor, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildFeaturedSection() {
    if (_isLoading) return _buildFeaturedShimmer();
    if (_nowPlaying.isEmpty) return const SizedBox();

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
          items: _nowPlaying.take(5).map((movie) {
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
                          imageUrl:
                              _tmdbService.getBackdropUrl(movie.backdropPath),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _shimmerBox(double.infinity, double.infinity),
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
                                fontSize: 9.sp,
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
                                    fontSize: 10.sp,
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
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    ...movie.genreNames.map(
                                      (genre) => Container(
                                        margin: const EdgeInsets.only(right: 6),
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
                                            fontSize: 9.sp,
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
                                            fontSize: 10.sp,
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
            _nowPlaying.take(5).length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _featuredIndex == index ? 20 : 6,
              height: 3,
              decoration: BoxDecoration(
                color: _featuredIndex == index
                    ? appthemecolor
                    : secondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSection({
    required String title,
    required List<TmdbMovie> movies,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: R.sectionHeight,
          child: isLoading
              ? _buildHorizontalShimmer()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return GestureDetector(
                      onTap: () => _navigateToDetails(movie),
                      child: Container(
                        width: R.movieCardWidth,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: appthemecolor.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'movie_${movie.id}_$title',
                                child: CachedNetworkImage(
                                  imageUrl: _tmdbService
                                      .getPosterUrl(movie.posterPath),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => _shimmerBox(
                                      R.movieCardWidth, R.movieCardHeight),
                                  errorWidget: (context, url, error) =>
                                      _errorBox(),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    gradient: heroGradient,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie.title,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: appthemecolor,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            movie.formattedRating,
                                            style: TextStyle(
                                              color: appthemecolor,
                                              fontSize: 9.sp,
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
      ],
    );
  }

  Widget _buildComingSoonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        _isLoading
            ? _buildHorizontalShimmer()
            : SizedBox(
                height: R.comingSoonSectionHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _upcoming.length,
                  itemBuilder: (context, index) {
                    return ComingSoon(movie: _upcoming[index]);
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Live Events',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildHorizontalShimmer();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No events available',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 13.sp,
                  ),
                ),
              );
            }
            return SizedBox(
              height: R.sectionHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return Container(
                    width: R.movieCardWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
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
                            fontSize: 10.sp,
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

  void _navigateToDetails(TmdbMovie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movie: movie),
      ),
    );
  }

  Widget _buildFeaturedShimmer() {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: surfaceColor2,
      child: Container(
        height: R.featuredHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: surfaceColor,
          highlightColor: surfaceColor2,
          child: Container(
            width: R.movieCardWidth,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
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
