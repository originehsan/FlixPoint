import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/services/watchlist_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_appbar.dart';
import 'package:movieticket/widgets/common/app_card.dart';
import 'package:movieticket/widgets/common/confirm_dialog.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/common/app_snackbar.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistService _watchlistService = WatchlistService();
  final TmdbService _tmdbService = TmdbService();

  // BUG 49 fix: local state + get()
  // instead of stream listener
  List<TmdbMovie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);
    try {
      final movies = await _watchlistService.getWatchlistOnce();
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmClearAll() async {
    await ConfirmDialog.show(
      context,
      title: 'Clear Watchlist',
      message: 'Remove all movies from your watchlist?',
      confirmText: 'Clear All',
      confirmColor: errorColor,
      icon: Icons.delete_sweep_rounded,
      iconColor: errorColor,
      onConfirm: () async {
        await _watchlistService.clearWatchlist();
        await _loadWatchlist();
        if (mounted) {
          AppSnackbar.success(
            context,
            'Watchlist cleared',
          );
        }
      },
    );
  }

  Future<void> _removeSingle(
    TmdbMovie movie,
  ) async {
    await ConfirmDialog.show(
      context,
      title: 'Remove from Watchlist',
      message: 'Remove "${movie.title}" from your watchlist?',
      confirmText: 'Remove',
      confirmColor: errorColor,
      icon: Icons.bookmark_remove_rounded,
      iconColor: errorColor,
      onConfirm: () async {
        await _watchlistService.removeFromWatchlist(
          movie.id,
        );
        await _loadWatchlist();
      },
    );
  }

  Future<bool> _confirmSwipeDismiss(
    TmdbMovie movie,
  ) async {
    bool confirmed = false;
    await ConfirmDialog.show(
      context,
      title: 'Remove from Watchlist',
      message: 'Remove "${movie.title}"?',
      confirmText: 'Remove',
      confirmColor: errorColor,
      icon: Icons.bookmark_remove_rounded,
      iconColor: errorColor,
      onConfirm: () async {
        confirmed = true;
        await _watchlistService.removeFromWatchlist(
          movie.id,
        );
        await _loadWatchlist();
      },
    );
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppAppBar(
        title: 'My Watchlist',
        actions: [
          GestureDetector(
            onTap: _confirmClearAll,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: errorColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: appthemecolor,
        backgroundColor: surfaceColor,
        onRefresh: _loadWatchlist,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: R.maxWidth),
            child: _isLoading
                ? _buildShimmer()
                : _movies.isEmpty
                    ? const EmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No movies saved',
                        subtitle:
                            'Tap the bookmark icon on any movie to save it here',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title:
                                '${_movies.length} movie${_movies.length > 1 ? 's' : ''} saved',
                            subtitle: 'Swipe left to remove',
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.horizontalPadding,
                                vertical: 4,
                              ),
                              itemCount: _movies.length,
                              itemBuilder: (context, index) {
                                final movie = _movies[index];
                                return _WatchlistItem(
                                  movie: movie,
                                  tmdbService: _tmdbService,
                                  onTap: () => Navigator.push(
                                    context,
                                    AppRoutes.scaleRoute(
                                      MovieDetailsScreen(
                                        movie: movie,
                                      ),
                                    ),
                                  ),
                                  onRemove: () => _removeSingle(
                                    movie,
                                  ),
                                  onDismissed: () =>
                                      _watchlistService.removeFromWatchlist(
                                    movie.id,
                                  ),
                                  onConfirmDismiss: () => _confirmSwipeDismiss(
                                    movie,
                                  ),
                                  index: index,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 16,
      ),
      itemCount: 5,
      itemBuilder: (_, __) => ShimmerBox(
        width: double.infinity,
        height: R.isPhone ? 130 : 150,
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}

class _WatchlistItem extends StatelessWidget {
  final TmdbMovie movie;
  final TmdbService tmdbService;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onDismissed;
  final Future<bool> Function() onConfirmDismiss;
  final int index;

  const _WatchlistItem({
    required this.movie,
    required this.tmdbService,
    required this.onTap,
    required this.onRemove,
    required this.onDismissed,
    required this.onConfirmDismiss,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Dismissible(
      key: Key(movie.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onConfirmDismiss(),
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: errorColor.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_rounded,
              color: errorColor,
              size: 28,
            ),
            const Gap(4),
            Text(
              'Remove',
              style: TextStyle(
                color: errorColor,
                fontSize: R.sp(11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: AppCard(
        onTap: onTap,
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: tmdbService.getPosterUrl(
                  movie.posterPath,
                ),
                width: R.isPhone ? 90 : 110,
                height: R.isPhone ? 130 : 150,
                fit: BoxFit.cover,
                placeholder: (_, __) => ShimmerBox(
                  width: R.isPhone ? 90 : 110,
                  height: R.isPhone ? 130 : 150,
                  borderRadius: 0,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: R.isPhone ? 90 : 110,
                  height: R.isPhone ? 130 : 150,
                  color: surfaceColor2,
                  child: const Icon(
                    Icons.movie,
                    color: appthemecolor,
                  ),
                ),
              ),
            ),
            const Gap(14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: R.sp(14),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(8),
                    Row(
                      children: [
                        AppBadge(
                          label: movie.formattedRating,
                          icon: Icons.star_rounded,
                          color: appthemecolor.withValues(alpha: 0.15),
                          textColor: appthemecolor,
                          hasGlow: false,
                        ),
                        const Gap(8),
                        Text(
                          movie.year,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(11),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    if (movie.genreNames.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: movie.genreNames
                            .take(2)
                            .map(
                              (g) => AppBadge(
                                label: g,
                                color: surfaceColor2,
                                textColor: secondaryColor,
                                hasGlow: false,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                margin: const EdgeInsets.only(
                  right: 14,
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.bookmark_remove_rounded,
                  color: errorColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
            delay: Duration(
              milliseconds: index * 60,
            ),
          ),
    );
  }
}
