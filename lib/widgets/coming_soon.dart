import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/moviedetails.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class ComingSoon extends StatelessWidget {
  final TmdbMovie movie;
  const ComingSoon({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final cardW = R.movieCardWidth;
    final cardH = R.movieCardHeight;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: ClipRect(
        child: SizedBox(
          width: cardW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(R.cardRadius),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                      height: cardH,
                      width: cardW,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: cardH,
                        width: cardW,
                        color: surfaceColor,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: cardH,
                        width: cardW,
                        color: surfaceColor,
                        child: const Icon(
                          Icons.movie,
                          color: appthemecolor,
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: appthemecolor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SOON',
                          style: TextStyle(
                            color: mobileBackgroundColor,
                            fontSize: R.sp(8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: appthemecolor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: appthemecolor,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              movie.formattedRating,
                              style: TextStyle(
                                color: appthemecolor,
                                fontSize: R.sp(8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                movie.title,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(11),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                movie.genreNames.take(2).join(', '),
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: R.sp(9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: secondaryColor,
                    size: R.sp(9),
                  ),
                  const SizedBox(width: 3),
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
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }
}
