class FyneCurrencyFormatter {
  static String format(double amount) {
    final fixed = amount.abs().toStringAsFixed(2);
    return fixed.replaceAll('.', ',');
  }

  static String formatWithSign(double amount) {
    final formatted = format(amount);
    if (amount > 0) return '+$formatted €';
    if (amount < 0) return '-$formatted €';
    return '$formatted €';
  }

  static double? parseInput(String input) {
    return double.tryParse(input.replaceAll(',', '.').trim());
  }
}
