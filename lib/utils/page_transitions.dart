import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class AppRoutes {
  // ═══════════════════════════════════════
  // MOVIE SCREENS - Scaled zoom
  // Movie card → Details
  // ═══════════════════════════════════════
  static Route scaleRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondary) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.scaled,
          child: page,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ═══════════════════════════════════════
  // BOOKING FLOW - Vertical slide up
  // Seat Selection → Payment → Ticket
  // ═══════════════════════════════════════
  static Route slideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondary) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.vertical,
          child: page,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ═══════════════════════════════════════
  // AUTH FLOW - Horizontal slide
  // SignIn → SignUp → OTP → Register → Home
  // ═══════════════════════════════════════
  static Route authRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondary) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.horizontal,
          child: page,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ═══════════════════════════════════════
  // HOME ENTRY - Scale + Fade celebration
  // Register/Login → Home (special moment)
  // ═══════════════════════════════════════
  static Route homeEntryRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ═══════════════════════════════════════
  // GENERAL - Fade only
  // Fallback for any other navigation
  // ═══════════════════════════════════════
  static Route fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ═══════════════════════════════════════
  // SEARCH - Horizontal from right
  // ═══════════════════════════════════════
  static Route slideRightRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondary) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.horizontal,
          child: page,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}
