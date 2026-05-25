import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final bool hasShadow;
  final bool hasGlow;
  final EdgeInsets? margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 16,
    this.hasShadow = true,
    this.hasGlow = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ??
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? surfaceColor,
          borderRadius:
              BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ??
                appthemecolor.withValues(alpha: 0.15),
          ),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: hasGlow
                        ? appthemecolor
                            .withValues(alpha: 0.15)
                        : Colors.black
                            .withValues(alpha: 0.1),
                    blurRadius: hasGlow ? 16 : 8,
                    spreadRadius: hasGlow ? 1 : 0,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}