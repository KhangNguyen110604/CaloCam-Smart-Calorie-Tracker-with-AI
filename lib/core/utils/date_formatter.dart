/// Date Formatter Utility
class DateFormatter {
  DateFormatter._();

  /// Format date to Vietnamese format: "Thứ 2, 14/10/2025"
  static String formatFullDate(DateTime date) {
    final weekday = _getVietnameseWeekday(date.weekday);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$weekday, $day/$month/$year';
  }

  /// Format date to short format: "14/10/2025"
  static String formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Format date to "14 Tháng 10, 2025"
  static String formatMediumDate(DateTime date) {
    final day = date.day;
    final month = _getVietnameseMonth(date.month);
    final year = date.year;
    return '$day $month, $year';
  }

  /// Format time to "07:30"
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format date and time to "14/10/2025 07:30"
  static String formatDateTime(DateTime date) {
    return '${formatShortDate(date)} ${formatTime(date)}';
  }

  /// Format date to YYYY-MM-DD (for database)
  static String formatDateOnly(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Alias for formatDateOnly (for consistency)
  static String formatDate(DateTime date) {
    return formatDateOnly(date);
  }

  /// Format date with weekday: "Thứ 2, 14/10/2025"
  static String formatDateWithWeekday(DateTime date) {
    final weekday = _getVietnameseWeekday(date.weekday);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$weekday, $day/$month/$year';
  }

  /// Format to relative time: "Hôm nay", "Hôm qua", "2 ngày trước"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else if (difference == -1) {
      return 'Ngày mai';
    } else if (difference > 1 && difference <= 7) {
      return '$difference ngày trước';
    } else if (difference < -1 && difference >= -7) {
      return '${difference.abs()} ngày nữa';
    } else {
      return formatShortDate(date);
    }
  }

  /// Format to "Sáng", "Trưa", "Chiều", "Tối"
  static String formatTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 11) {
      return 'Sáng';
    } else if (hour >= 11 && hour < 13) {
      return 'Trưa';
    } else if (hour >= 13 && hour < 18) {
      return 'Chiều';
    } else {
      return 'Tối';
    }
  }

  /// Get Vietnamese weekday name
  static String _getVietnameseWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  /// Get Vietnamese month name
  static String _getVietnameseMonth(int month) {
    return 'Tháng $month';
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return endOfDay(date.add(Duration(days: 7 - weekday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Parse date from string "dd/MM/yyyy"
  static DateTime? parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}

