import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class CinemaCardWidget extends StatelessWidget {
  final Map<String, dynamic> cinema;
  final String cinemaId;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const CinemaCardWidget({
    super.key,
    required this.cinema,
    required this.cinemaId,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? appthemecolor.withValues(alpha: 0.08)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? appthemecolor
                : appthemecolor.withValues(alpha: 0.15),
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Cinema logo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: cinema['logo'] ?? '',
                height: 45,
                width: 60,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => Container(
                  height: 45,
                  width: 60,
                  color: surfaceColor2,
                  child: const Icon(
                    Icons.movie,
                    color: appthemecolor,
                  ),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cinema['name'] ?? '',
                    style: TextStyle(
                      color: isSelected
                          ? appthemecolor
                          : primaryColor,
                      fontSize: R.sp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isSelected
                            ? appthemecolor
                            : secondaryColor,
                        size: 12,
                      ),
                      const Gap(3),
                      Expanded(
                        child: Text(
                          cinema['address'] ?? '',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(11),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (cinema['distance'] != null) ...[
                    const Gap(2),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          color: successColor,
                          size: 12,
                        ),
                        const Gap(3),
                        Text(
                          '${cinema['distance']} km away',
                          style: TextStyle(
                            color: successColor,
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Selected checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 32 : 0,
              height: isSelected ? 32 : 0,
              decoration: BoxDecoration(
                color: appthemecolor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: appthemecolor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.black,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
        );
  }
}