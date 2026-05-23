import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class TheatreStatusWidget extends StatelessWidget {
  final bool isInTheatres;
  final bool isLoading;

  const TheatreStatusWidget({
    super.key,
    required this.isInTheatres,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    if (isLoading) return const SizedBox();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 8,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isInTheatres
              ? successColor.withValues(alpha: 0.1)
              : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isInTheatres
                ? successColor.withValues(alpha: 0.4)
                : secondaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isInTheatres
                    ? successColor.withValues(alpha: 0.15)
                    : surfaceColor2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInTheatres
                    ? Icons.theaters_rounded
                    : Icons.movie_filter_rounded,
                color: isInTheatres ? successColor : secondaryColor,
                size: R.sp(20),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isInTheatres
                        ? 'Now Playing in Theatres'
                        : 'Not Currently in Theatres',
                    style: TextStyle(
                      color: isInTheatres
                          ? successColor
                          : secondaryColor,
                      fontSize: R.sp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isInTheatres
                        ? 'Book your tickets now!'
                        : 'Not playing in Indian theatres',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}