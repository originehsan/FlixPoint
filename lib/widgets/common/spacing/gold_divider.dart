import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class GoldDivider extends StatelessWidget {
  final double opacity;
  final EdgeInsets? margin;
  final double height;

  const GoldDivider({
    super.key,
    this.opacity = 0.15,
    this.margin,
    this.height = 1,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Container(
      height: height,
      margin: margin ??
          EdgeInsets.symmetric(
            horizontal: R.horizontalPadding,
            vertical: 8,
          ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            appthemecolor.withValues(alpha: opacity),
            appthemecolor.withValues(alpha: opacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }
}