import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class InfoChipRow extends StatelessWidget {
  final TmdbMovie movie;
  final String runtime;

  const InfoChipRow({
    super.key,
    required this.movie,
    required this.runtime,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          _infoChip(
            Icons.star_rounded,
            'Rating',
            movie.formattedRating,
            appthemecolor,
          ),
          const Gap(10),
          if (runtime.isNotEmpty) ...[
            _infoChip(
              Icons.access_time_rounded,
              'Duration',
              runtime,
              secondaryColor,
            ),
            const Gap(10),
          ],
          _infoChip(
            Icons.calendar_month_rounded,
            'Year',
            movie.year,
            secondaryColor,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _infoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const Gap(4),
            Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}