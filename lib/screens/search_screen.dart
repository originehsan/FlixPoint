import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  List<TmdbMovie> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    final results = await _tmdbService.searchMovies(query);
    if (mounted) {
      setState(() {
        _results = results.map((m) => TmdbMovie.fromJson(m)).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: appthemecolor,
              size: 16,
            ),
          ),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appthemecolor.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(15),
            ),
            decoration: InputDecoration(
              hintText: 'Search movies...',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: R.sp(15),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: appthemecolor,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surfaceColor2,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.clear,
                          color: secondaryColor,
                          size: 16,
                        ),
                      ),
                    )
                  : null,
            ),
            onSubmitted: _search,
            onChanged: (value) {
              setState(() {});
              if (value.length > 2) _search(value);
            },
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: appthemecolor),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(14),
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appthemecolor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: appthemecolor,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Find your movie',
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(20),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by title, genre or actor',
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(13),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                color: secondaryColor,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(18),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            R.horizontalPadding, 12,
            R.horizontalPadding, 8,
          ),
          child: Text(
            '${_results.length} results found',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(13),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
              vertical: 8,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: R.gridColumns,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final movie = _results[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MovieDetailsScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(R.cardRadius),
                    border: Border.all(
                      color: appthemecolor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
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
                          imageUrl: _tmdbService
                              .getPosterUrl(movie.posterPath),
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
                          errorWidget: (context, url, error) =>
                              Container(
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
                            decoration: const BoxDecoration(
                              gradient: heroGradient,
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
                                    fontSize: R.sp(11),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: appthemecolor,
                                      size: 11,
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
                                    const Spacer(),
                                    Text(
                                      movie.year,
                                      style: TextStyle(
                                        color: secondaryColor,
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
                ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 40),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}