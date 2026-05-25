import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';

class AppRoutes {
  // ═══════════════════════════════════════
  // MOVIE SCREENS - Scaled zoom (OpenContainer style)
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
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }

  // ═══════════════════════════════════════
  // BOOKING FLOW - Spring slide up
  // Seat Selection → Payment → Ticket
  // ═══════════════════════════════════════
  static Route slideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }

  // ═══════════════════════════════════════
  // AUTH FLOW - iOS native horizontal
  // SignIn → SignUp → OTP → Register
  // ═══════════════════════════════════════
  static Route authRoute(Widget page) {
    return CupertinoPageRoute(builder: (_) => page);
  }

  // ═══════════════════════════════════════
  // HOME ENTRY - Scale + Fade celebration
  // Register/Login → Home
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
  // SEARCH - Horizontal slide
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
