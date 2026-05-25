import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/services/search_history_service.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_card.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/app_loader.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/movie/watchlist_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final SearchHistoryService _historyService = SearchHistoryService();
  final TextEditingController _searchController = TextEditingController();

  // Debounce timer prevents rapid API calls
  // while user is still typing
  Timer? _debounceTimer;

  List<TmdbMovie> _results = [];
  List<String> _history = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    await _historyService.addSearch(query.trim());
    await _loadHistory();

    final results = await _tmdbService.searchMovies(query);
    if (mounted) {
      setState(() {
        _results = results.map((m) => TmdbMovie.fromJson(m)).toList();
        _isLoading = false;
      });
    }
  }

  // Debounced search — waits 500ms after
  // last keystroke before firing API call
  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    if (value.length > 2) {
      _debounceTimer = Timer(
        const Duration(milliseconds: 500),
        () => _search(value),
      );
    }
  }

  Future<void> _removeHistory(String query) async {
    await _historyService.removeSearch(query);
    await _loadHistory();
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        // Back button matches AppAppBar style
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
                        _debounceTimer?.cancel();
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
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
            onChanged: _onSearchChanged,
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
    // AppLoader replaces CircularProgressIndicator
    if (_isLoading) {
      return Center(
        child: AppLoader(),
      );
    }

    if (!_hasSearched) {
      return _buildHistorySection();
    }

    if (_results.isEmpty) {
      // EmptyState replaces custom empty widget
      return const EmptyState(
        icon: Icons.movie_filter_rounded,
        title: 'No results found',
        subtitle: 'Try a different search term',
      );
    }

    return _buildResults();
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      // EmptyState replaces custom empty widget
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Find your movie',
        subtitle: 'Search by title, genre or actor',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            R.horizontalPadding,
            16,
            R.horizontalPadding,
            8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: appthemecolor,
                size: 18,
              ),
              const Gap(8),
              Text(
                'Recent Searches',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(15),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: appthemecolor,
                    fontSize: R.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final query = _history[index];
              // AppCard replaces GestureDetector+Container
              return AppCard(
                onTap: () {
                  _searchController.text = query;
                  _search(query);
                },
                borderRadius: 12,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                borderColor: appthemecolor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: secondaryColor,
                      size: 16,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        query,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: R.sp(14),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeHistory(query),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: surfaceColor2,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: secondaryColor,
                          size: 14,
                        ),
                      ),
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
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            R.horizontalPadding,
            12,
            R.horizontalPadding,
            8,
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
                onTap: () => Navigator.push(
                  context,
                  AppRoutes.scaleRoute(
                    MovieDetailsScreen(movie: movie),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(R.cardRadius),
                    border: Border.all(
                      color: appthemecolor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(R.cardRadius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _tmdbService.getPosterUrl(
                            movie.posterPath,
                          ),
                          fit: BoxFit.cover,
                          // ShimmerBox replaces
                          // CircularProgressIndicator placeholder
                          placeholder: (_, __) => const ShimmerBox(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: surfaceColor,
                            child: const Icon(
                              Icons.movie,
                              color: appthemecolor,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: WatchlistButton(
                            movie: movie,
                            size: 14,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                const Gap(3),
                                Row(
                                  children: [
                                    // AppBadge replaces
                                    // rating Container
                                    AppBadge(
                                      label: movie.formattedRating,
                                      icon: Icons.star_rounded,
                                      color:
                                          appthemecolor.withValues(alpha: 0.2),
                                      hasGlow: false,
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
                      delay: Duration(
                        milliseconds: index * 40,
                      ),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}
