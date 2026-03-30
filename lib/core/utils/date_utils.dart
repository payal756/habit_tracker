class AppDateUtils {
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = normalizeDate(from);
    to = normalizeDate(to);
    return to.difference(from).inDays;
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return normalizeDate(date1) == normalizeDate(date2);
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static DateTime getTodayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
