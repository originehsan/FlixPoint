import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor; // ADD
  final IconData? icon;
  final bool hasDot;
  final bool hasGlow;

  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor, // ADD
    this.icon,
    this.hasDot = false,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final badgeColor = color ?? appthemecolor;
    final labelColor = textColor ?? Colors.white; // ADD
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: labelColor, // USE
                shape: BoxShape.circle,
              ),
            ),
            const Gap(5),
          ],
          if (icon != null) ...[
            Icon(
              icon,
              color: labelColor, // USE
              size: 10,
            ),
            const Gap(4),
          ],
          Text(
            label,
            style: TextStyle(
              color: labelColor, // USE
              fontSize: R.sp(9),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}