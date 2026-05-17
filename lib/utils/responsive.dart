import 'package:flutter/material.dart';

class R {
  static late MediaQueryData _mq;
  static late double _w;
  static late double _h;

  static void init(BuildContext context) {
    _mq = MediaQuery.of(context);
    _w = _mq.size.width;
    _h = _mq.size.height;
  }

  // Screen dimensions
  static double get screenWidth => _w;
  static double get screenHeight => _h;

  // Breakpoints
  static bool get isSmallPhone => _w < 360;
  static bool get isPhone => _w < 600;
  static bool get isTablet => _w >= 600 && _w < 900;
  static bool get isDesktop => _w >= 900;

  // Responsive width percentage
  static double wp(double percent) => _w * percent / 100;

  // Responsive height percentage
  static double hp(double percent) => _h * percent / 100;

  // Responsive font size
  static double sp(double size) {
    if (_w > 900) return size * 1.3;
    if (_w > 600) return size * 1.15;
    if (_w < 360) return size * 0.9;
    return size;
  }

  // Responsive padding/margin
  static double px(double size) {
    if (_w > 900) return size * 1.5;
    if (_w > 600) return size * 1.2;
    if (_w < 360) return size * 0.85;
    return size;
  }

  // Movie card width
  static double get movieCardWidth {
    if (_w > 1200) return 180;
    if (_w > 900) return 160;
    if (_w > 600) return 150;
    if (_w < 360) return 110;
    return 130;
  }

  // Movie card height (poster)
  static double get movieCardHeight {
    if (_w > 1200) return 260;
    if (_w > 900) return 240;
    if (_w > 600) return 210;
    if (_w < 360) return 160;
    return 190;
  }

  // Featured banner height
  static double get featuredHeight {
    if (_w > 1200) return 450;
    if (_w > 900) return 380;
    if (_w > 600) return 320;
    if (_w < 360) return 220;
    return 260;
  }

  // Horizontal section height
  static double get sectionHeight {
    if (_w > 900) return 260;
    if (_w > 600) return 230;
    if (_w < 360) return 170;
    return 200;
  }

  // Coming soon section height
  static double get comingSoonSectionHeight {
    return movieCardHeight + 80;
  }

  // Search grid columns
  static int get gridColumns {
    if (_w > 1200) return 5;
    if (_w > 900) return 4;
    if (_w > 600) return 3;
    return 2;
  }

  // Max content width for desktop
  static double get maxWidth {
    if (_w > 1400) return 1200;
    if (_w > 1200) return 1000;
    return _w;
  }

  // Horizontal padding
  static double get horizontalPadding {
    if (_w > 900) return 32;
    if (_w > 600) return 24;
    return 16;
  }

  // Border radius
  static double get cardRadius {
    if (_w > 600) return 16;
    return 12;
  }

  // Bottom nav height
  static double get bottomNavHeight {
    if (_w > 600) return 70;
    return 60;
  }

  // Appbar height
  static double get appBarHeight {
    if (_w > 600) return 70;
    return 56;
  }
}
