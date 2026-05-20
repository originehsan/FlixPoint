import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';

enum BookingStatus { upcoming, today, expired }

class BookingUtils {
  /// Parse booking date and time string
  /// date format: "2026-5-20"
  /// time format: "7:00 PM"
  static DateTime? parseShowDateTime(
    String date,
    String time,
  ) {
    try {
      final dateParts = date.split('-');
      if (dateParts.length != 3) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time "7:00 PM" or "10:00 AM"
      final timeParts = time.split(' ');
      if (timeParts.length != 2) return null;

      final clockParts = timeParts[0].split(':');
      if (clockParts.length != 2) return null;

      int hour = int.parse(clockParts[0]);
      final minute = int.parse(clockParts[1]);
      final isPm = timeParts[1].toUpperCase() == 'PM';

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Get booking status based on show date/time
  static BookingStatus getStatus(String date, String time) {
    final showTime = parseShowDateTime(date, time);
    if (showTime == null) return BookingStatus.upcoming;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final showDay = DateTime(
      showTime.year,
      showTime.month,
      showTime.day,
    );

    if (showTime.isBefore(now)) {
      return BookingStatus.expired;
    } else if (showDay.isAtSameMomentAs(today)) {
      return BookingStatus.today;
    } else {
      return BookingStatus.upcoming;
    }
  }

  /// Get status label
  static String getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.today:
        return 'Today';
      case BookingStatus.expired:
        return 'Expired';
    }
  }

  /// Get status color
  static Color getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return successColor;
      case BookingStatus.today:
        return const Color(0xFF00D4FF);
      case BookingStatus.expired:
        return const Color(0xFF666666);
    }
  }

  /// Get status icon
  static IconData getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Icons.event_available_rounded;
      case BookingStatus.today:
        return Icons.today_rounded;
      case BookingStatus.expired:
        return Icons.event_busy_rounded;
    }
  }

  /// Is ticket still valid (show not yet started)
  static bool isValid(String date, String time) {
    final showTime = parseShowDateTime(date, time);
    if (showTime == null) return false;
    return showTime.isAfter(DateTime.now());
  }

  /// Time remaining until show
  static String timeRemaining(String date, String time) {
    final showTime = parseShowDateTime(date, time);
    if (showTime == null) return '';

    final now = DateTime.now();
    if (showTime.isBefore(now)) return 'Show ended';

    final diff = showTime.difference(now);

    if (diff.inDays > 0) {
      return 'in ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'in ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    } else {
      return 'in ${diff.inMinutes} min';
    }
  }
}
