import 'package:flutter/material.dart';
import 'responsive.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: R.maxWidth),
        child: child,
      ),
    );
  }
}
