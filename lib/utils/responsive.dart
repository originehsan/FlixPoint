import 'package:flutter/material.dart';

class R {
  static double _w = 375;
  static double _h = 812;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _w = mq.size.width;
    _h = mq.size.height;
  }

  static double get w => _w;
  static double get h => _h;

  static bool get isSmallPhone => _w < 360;
  static bool get isPhone => _w < 600;
  static bool get isTablet => _w >= 600 && _w < 900;
  static bool get isDesktop => _w >= 900;

  static double wp(double percent) => _w * percent / 100;
  static double hp(double percent) => _h * percent / 100;

  static double sp(double size) {
    if (_w > 1200) return size * 1.4;
    if (_w > 900) return size * 1.25;
    if (_w > 600) return size * 1.1;
    if (_w < 360) return size * 0.85;
    return size;
  }

  static double px(double size) {
    if (_w > 900) return size * 1.5;
    if (_w > 600) return size * 1.2;
    if (_w < 360) return size * 0.85;
    return size;
  }

  static double get movieCardWidth {
    if (_w > 1200) return 180;
    if (_w > 900) return 160;
    if (_w > 600) return 150;
    if (_w < 360) return 110;
    return 130;
  }

  static double get movieCardHeight {
    if (_w > 1200) return 260;
    if (_w > 900) return 240;
    if (_w > 600) return 210;
    if (_w < 360) return 160;
    return 190;
  }

  static double get featuredHeight {
    if (_w > 1200) return 450;
    if (_w > 900) return 380;
    if (_w > 600) return 320;
    if (_w < 360) return 220;
    return 260;
  }

  static double get sectionHeight {
    if (_w > 900) return 260;
    if (_w > 600) return 230;
    if (_w < 360) return 170;
    return 200;
  }

  static double get comingSoonSectionHeight {
    return movieCardHeight + 90;
  }

  static int get gridColumns {
    if (_w > 1200) return 5;
    if (_w > 900) return 4;
    if (_w > 600) return 3;
    return 2;
  }

  static double get maxWidth {
    if (_w > 1400) return 1200;
    if (_w > 1200) return 1000;
    return _w;
  }

  static double get horizontalPadding {
    if (_w > 900) return 32;
    if (_w > 600) return 24;
    return 16;
  }

  static double get cardRadius {
    if (_w > 600) return 16;
    return 12;
  }

  static double get seatSize {
    if (_w > 900) return 40;
    if (_w > 600) return 32;
    return 25;
  }

  static double get seatFontSize {
    if (_w > 900) return 10;
    if (_w > 600) return 9;
    return 7;
  }

  static double get castCardWidth {
    if (_w > 900) return 100;
    if (_w > 600) return 90;
    return 80;
  }

  static double get castCardHeight {
    if (_w > 900) return 140;
    if (_w > 600) return 130;
    return 120;
  }

  static double get circleAvatarRadius {
    if (_w > 900) return 40;
    if (_w > 600) return 35;
    return 28;
  }
}
