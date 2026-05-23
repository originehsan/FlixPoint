import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: surfaceColor,
      highlightColor: surfaceColor2,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius:
              BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}