class FyneDateUtils {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getStartOfWeek(DateTime date) {
    final normalized = startOfDay(date);
    final daysFromMonday = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: daysFromMonday));
  }

  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 7));
  }

  static bool isSameWeek(DateTime a, DateTime b) {
    final startA = getStartOfWeek(a);
    final startB = getStartOfWeek(b);
    return startA.year == startB.year &&
        startA.month == startB.month &&
        startA.day == startB.day;
  }
}
