import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: appthemecolor),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: primaryColor, fontSize: R.sp(15)),
          decoration: InputDecoration(
            hintText: 'Search movies...',
            hintStyle: TextStyle(color: hintColor, fontSize: R.sp(15)),
            border: InputBorder.none,
          ),
          onSubmitted: _search,
          onChanged: (value) {
            if (value.length > 2) _search(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: secondaryColor),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _hasSearched = false;
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: appthemecolor),
      );
    }
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: appthemecolor, size: 60),
            const SizedBox(height: 16),
            Text(
              'Search for movies',
              style: TextStyle(color: secondaryColor, fontSize: R.sp(16)),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(color: secondaryColor, fontSize: 16.sp),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: R.gridColumns,
        childAspectRatio: 0.65,
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
                builder: (context) => MovieDetailsScreen(movie: movie),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _tmdbService.getPosterUrl(movie.posterPath),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: surfaceColor,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: surfaceColor,
                      child: const Icon(Icons.movie, color: appthemecolor),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(gradient: heroGradient),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: appthemecolor, size: 10),
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
          ).animate().fadeIn(delay: Duration(milliseconds: index * 50)),
        );
      },
    );
  }
}
