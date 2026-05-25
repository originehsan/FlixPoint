import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/movie/watchlist_button.dart';

class MovieCardWidget extends StatelessWidget {
  final TmdbMovie movie;
  final int index;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;
  final String? heroSection;

  const MovieCardWidget({
    super.key,
    required this.movie,
    required this.index,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
    this.heroSection,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final tmdbService = TmdbService();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: R.movieCardWidth,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // BUG 29 fix: Hero tag includes
            // section to avoid conflicts
            Hero(
              tag: heroSection != null
                  ? 'movie_${movie.id}_$heroSection'
                  : 'movie_${movie.id}_card_$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  R.cardRadius,
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          tmdbService.getPosterUrl(
                        movie.posterPath,
                      ),
                      height: R.movieCardHeight,
                      width: R.movieCardWidth,
                      fit: BoxFit.cover,
                      // ShimmerBox replaces CPI
                      placeholder: (_, __) =>
                          ShimmerBox(
                        height: R.movieCardHeight,
                        width: R.movieCardWidth,
                        borderRadius: R.cardRadius,
                      ),
                      errorWidget: (_, __, ___) =>
                          Container(
                        height: R.movieCardHeight,
                        width: R.movieCardWidth,
                        color: surfaceColor,
                        child: const Icon(
                          Icons.movie,
                          color: appthemecolor,
                          size: 30,
                        ),
                      ),
                    ),

                    // AppBadge replaces custom Container
                    if (badgeText != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: AppBadge(
                          label: badgeText!,
                          color: badgeColor ??
                              appthemecolor,
                          hasGlow: true,
                        ),
                      ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: WatchlistButton(
                        movie: movie,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Gap(6),

            Text(
              movie.title,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(11),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Gap(2),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: appthemecolor,
                  size: R.sp(11),
                ),
                const Gap(3),
                Text(
                  movie.formattedRating,
                  style: TextStyle(
                    color: appthemecolor,
                    fontSize: R.sp(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(6),
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
    ).animate().fadeIn(
          delay: Duration(
            milliseconds: index * 50,
          ),
        );
  }
}