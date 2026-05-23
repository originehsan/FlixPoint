import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

enum BookingStatus { upcoming, completed, cancelled, expired }

class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  String get _label {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
    }
  }

  Color get _color {
    switch (status) {
      case BookingStatus.upcoming:
        return successColor;
      case BookingStatus.completed:
        return appthemecolor;
      case BookingStatus.cancelled:
        return errorColor;
      case BookingStatus.expired:
        return secondaryColor;
    }
  }

  IconData get _icon {
    switch (status) {
      case BookingStatus.upcoming:
        return Icons.access_time_rounded;
      case BookingStatus.completed:
        return Icons.check_circle_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.expired:
        return Icons.event_busy_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            color: _color,
            size: R.sp(11),
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: R.sp(10),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}