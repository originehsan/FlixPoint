import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

enum SnackbarType { success, error, info, warning }

class AppSnackbar {
  // Never instantiate — static use only
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final color = _getColor(type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const Gap(10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: R.sp(13),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.fromLTRB(
            R.horizontalPadding,
            0,
            R.horizontalPadding,
            16,
          ),
        ),
      );
  }

  static void success(
    BuildContext context,
    String message,
  ) =>
      show(
        context,
        message: message,
        type: SnackbarType.success,
      );

  static void error(
    BuildContext context,
    String message,
  ) =>
      show(
        context,
        message: message,
        type: SnackbarType.error,
      );

  static void info(
    BuildContext context,
    String message,
  ) =>
      show(
        context,
        message: message,
        type: SnackbarType.info,
      );

  static void warning(
    BuildContext context,
    String message,
  ) =>
      show(
        context,
        message: message,
        type: SnackbarType.warning,
      );

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return successColor;
      case SnackbarType.error:
        return errorColor;
      case SnackbarType.warning:
        return warningColor;
      case SnackbarType.info:
        return appthemecolor;
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_rounded;
      case SnackbarType.warning:
        return Icons.warning_rounded;
      case SnackbarType.info:
        return Icons.info_rounded;
    }
  }
}