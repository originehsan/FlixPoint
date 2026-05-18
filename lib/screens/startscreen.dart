import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movieticket/auth/signin.dart';
import 'package:movieticket/auth/signup.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.75,
    initialPage: 1,
  );
  final TmdbService _tmdbService = TmdbService();
  int _currentIndex = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final movieProvider = Provider.of<MovieProvider>(context);
    final movies = movieProvider.nowPlaying.isNotEmpty
        ? movieProvider.nowPlaying.take(5).toList()
        : movieProvider.popular.take(5).toList();

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: R.maxWidth),
            child: Column(
              children: [
                // App bar
                _buildAppBar(),

                SizedBox(height: R.px(20)),

                // Movie carousel
                _buildMovieCarousel(movies),

                SizedBox(height: R.px(24)),

                // App name and tagline
                _buildBranding(),

                SizedBox(height: R.px(16)),

                // Page indicators
                _buildIndicators(movies.length),

                SizedBox(height: R.px(32)),

                // Buttons
                _buildButtons(),

                SizedBox(height: R.px(16)),

                // Terms
                _buildTerms(),

                SizedBox(height: R.px(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/appicon.svg',
            height: 32,
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [appthemecolor, goldLight],
            ).createShader(bounds),
            child: Text(
              'FlixPoint',
              style: TextStyle(
                color: Colors.white,
                fontSize: R.sp(22),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildMovieCarousel(List<TmdbMovie> movies) {
    if (movies.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: const Center(
          child: CircularProgressIndicator(color: appthemecolor),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      child: PageView.builder(
        controller: _pageController,
        itemCount: movies.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final movie = movies[index];
          final isActive = index == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isActive ? 0 : 24,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? appthemecolor.withValues(alpha: 0.8)
                    : appthemecolor.withValues(alpha: 0.2),
                width: isActive ? 2 : 0.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: appthemecolor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _tmdbService.getPosterUrl(movie.posterPath),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: surfaceColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: appthemecolor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
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
                    decoration: const BoxDecoration(
                      gradient: heroGradient,
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: appthemecolor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.formattedRating,
                                style: TextStyle(
                                  color: appthemecolor,
                                  fontSize: R.sp(12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (movie.genreNames.isNotEmpty)
                                Text(
                                  movie.genreNames.first,
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontSize: R.sp(11),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildBranding() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [appthemecolor, goldLight],
          ).createShader(bounds),
          child: Text(
            'Book. Watch. Enjoy.',
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(26),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your premium cinema experience awaits',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(13),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentIndex == index ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? appthemecolor
                : secondaryColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            boxShadow: _currentIndex == index
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
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Column(
        children: [
          // Sign In button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              AppRoutes.authRoute(
                const LoginIn(),
              ),
            ),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [appthemecolor, goldDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: R.sp(16),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sign Up button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              AppRoutes.authRoute(
                const SignUp(),
              ),
            ),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: appthemecolor,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Create Account',
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: R.sp(16),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildTerms() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Text(
        'By signing in or signing up, you agree to our Terms of Service and Privacy Policy',
        style: TextStyle(
          color: hintColor,
          fontSize: R.sp(11),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
