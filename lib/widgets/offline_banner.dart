import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: errorColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'No internet connection',
            style: TextStyle(
              color: errorColor,
              fontSize: R.sp(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: errorColor,
                fontSize: R.sp(12),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
