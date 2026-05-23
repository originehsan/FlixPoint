import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

enum SeatState { available, selected, booked, locked }

class SeatWidget extends StatelessWidget {
  final String seatName;
  final SeatState state;
  final Color tierColor;
  final VoidCallback? onTap;

  const SeatWidget({
    super.key,
    required this.seatName,
    required this.state,
    required this.tierColor,
    this.onTap,
  });

  Color get _backgroundColor {
    switch (state) {
      case SeatState.available:
        return tierColor.withValues(alpha: 0.15);
      case SeatState.selected:
        return appthemecolor;
      case SeatState.booked:
        return const Color(0xFF1A0A0A);
      case SeatState.locked:
        return const Color(0xFF2A2A2A);
    }
  }

  Color get _borderColor {
    switch (state) {
      case SeatState.available:
        return tierColor.withValues(alpha: 0.5);
      case SeatState.selected:
        return appthemecolor;
      case SeatState.booked:
        return const Color(0xFF3A1A1A);
      case SeatState.locked:
        return const Color(0xFF444444);
    }
  }

  Color get _textColor {
    switch (state) {
      case SeatState.available:
        return tierColor.withValues(alpha: 0.8);
      case SeatState.selected:
        return Colors.black;
      case SeatState.booked:
        return const Color(0xFF3A1A1A);
      case SeatState.locked:
        return const Color(0xFF555555);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final isInteractable = state == SeatState.available ||
        state == SeatState.selected;

    return GestureDetector(
      onTap: isInteractable
          ? () {
              HapticFeedback.lightImpact();
              onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: R.seatSize,
        height: R.seatSize,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(3),
          ),
          border: Border.all(
            color: _borderColor,
            width: state == SeatState.selected ? 1.5 : 1,
          ),
          boxShadow: state == SeatState.selected
              ? [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: state == SeatState.booked
            ? Icon(
                Icons.close_rounded,
                color: const Color(0xFF3A1A1A),
                size: R.seatFontSize + 2,
              )
            : state == SeatState.locked
                ? Icon(
                    Icons.lock_rounded,
                    color: const Color(0xFF555555),
                    size: R.seatFontSize,
                  )
                : state == SeatState.selected
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: R.seatFontSize,
                          ),
                          Text(
                            seatName,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: R.seatFontSize - 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        seatName,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: R.seatFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
      ),
    );
  }
}