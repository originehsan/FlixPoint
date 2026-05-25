import 'package:flutter/material.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/widgets/common/app_snackbar.dart';

extension ContextExtensions on BuildContext {
  // Screen dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isPhone => screenWidth < 600;

  // Navigation
  void pop([dynamic result]) => Navigator.pop(this, result);

  void push(Widget screen) => Navigator.push(
        this,
        AppRoutes.slideUpRoute(screen),
      );

  void pushReplace(Widget screen) => Navigator.pushReplacement(
        this,
        AppRoutes.scaleRoute(screen),
      );

  void pushAndClearStack(Widget screen) => Navigator.pushAndRemoveUntil(
        this,
        AppRoutes.scaleRoute(screen),
        (_) => false,
      );

  // Snackbars
  void showSuccess(String message) => AppSnackbar.success(this, message);

  void showError(String message) => AppSnackbar.error(this, message);

  void showInfo(String message) => AppSnackbar.info(this, message);

  void showWarning(String message) => AppSnackbar.warning(this, message);

  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
}
