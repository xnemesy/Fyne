class FyneDateFormatter {
  static const List<String> _months = <String>[
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];

  static const List<String> _weekdays = <String>[
    'lunedì',
    'martedì',
    'mercoledì',
    'giovedì',
    'venerdì',
    'sabato',
    'domenica',
  ];

  static String formatFull(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  static String formatMonthYear(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  static String formatShort(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String formatWeekdayFull(DateTime date) {
    return '${_weekdays[date.weekday - 1]}, ${formatFull(date)}';
  }
}
