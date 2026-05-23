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
import 'package:movieticket/widgets/common/appbar/app_appbar.dart';
import 'package:movieticket/widgets/common/cards/app_card.dart';
import 'package:movieticket/widgets/common/dialogs/confirm_dialog.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/common/snackbars/app_snackbar.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistService _watchlistService = WatchlistService();
  final TmdbService _tmdbService = TmdbService();

  //  ConfirmDialog.show() instead of
  // duplicate dialog code x3
  Future<void> _confirmClearAll() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clear Watchlist',
      message: 'Remove all movies from your watchlist?',
      confirmText: 'Clear All', // ← was confirmLabel
      cancelText: 'Cancel', // ← was cancelLabel
      confirmColor: errorColor,
      icon: Icons.delete_sweep_rounded,
      onConfirm: () {}, // ← ADD this
    );
    if (confirmed==true && mounted) {
      await _watchlistService.clearWatchlist();
      //  AppSnackbar instead of ScaffoldMessenger
      if (mounted) {
        AppSnackbar.success(
          context,
          'Watchlist cleared',
        );
      }
    }
  }

  Future<void> _confirmRemoveSingle(
    TmdbMovie movie,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove from Watchlist',
      message: 'Remove "${movie.title}" from your watchlist?',
      confirmText: 'Remove', // ← was confirmLabel
      cancelText: 'Cancel', // ← was cancelLabel
      confirmColor: errorColor,
      icon: Icons.bookmark_remove_rounded,
      onConfirm: () {}, // ← ADD this
    );
    if (confirmed==true && mounted) {
      await _watchlistService.removeFromWatchlist(movie.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      //  AppAppBar instead of custom AppBar
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: StreamBuilder<List<TmdbMovie>>(
            stream: _watchlistService.getWatchlistStream(),
            builder: (context, snapshot) {
              // ✅ ShimmerBox instead of CPI
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmer();
              }

              final movies = snapshot.data ?? [];

              // ✅ EmptyState instead of custom empty
              if (movies.isEmpty) {
                return EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'No movies saved',
                  subtitle:
                      'Tap the bookmark icon on any\nmovie to save it here',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ SectionHeader instead of
                  // custom row with Container bar
                  SectionHeader(
                    title:
                        '${movies.length} movie${movies.length > 1 ? 's' : ''} saved',
                    subtitle: 'Swipe left to remove',
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.horizontalPadding,
                        vertical: 4,
                      ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
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
                          onRemove: () => _confirmRemoveSingle(
                            movie,
                          ),
                          onDismissed: () =>
                              _watchlistService.removeFromWatchlist(
                            movie.id,
                          ),
                          onConfirmDismiss: () async {
                            return await ConfirmDialog.show(
                                  context,
                                  title: 'Remove from Watchlist',
                                  message: 'Remove "${movie.title}"?',
                                  confirmText: 'Remove', // ← was confirmLabel
                                  confirmColor: errorColor,
                                  icon: Icons.bookmark_remove_rounded,
                                  onConfirm: () {}, // ← ADD this
                                ) ??
                                false;
                          },
                          index: index,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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

// ═══════════════════════════════════
// Extracted watchlist item widget
// Keeps build() method clean
// ═══════════════════════════════════
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
      // Swipe background
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
      // AppCard instead of GestureDetector+Container
      child: AppCard(
        onTap: onTap,
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Poster with shimmer placeholder
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
                // ✅ ShimmerBox placeholder
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

            // Movie info
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
                        // AppBadge instead of
                        // custom rating Container
                        AppBadge(
                          label: movie.formattedRating,
                          icon: Icons.star_rounded,
                          color: appthemecolor.withValues(alpha: 0.15),
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
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceColor2,
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontSize: R.sp(10),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),

            // Remove button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                margin: const EdgeInsets.only(right: 14),
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
            delay: Duration(milliseconds: index * 60),
          ),
    );
  }
}
