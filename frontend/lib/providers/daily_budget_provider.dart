import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget_provider.dart';

class DailyBudgetInfo {
  final double dailyAllowance;
  final double totalRemaining;
  final int daysRemaining;
  final bool isExhausted;
  final double dailyAverageNeeded;

  DailyBudgetInfo({
    required this.dailyAllowance,
    required this.totalRemaining,
    required this.daysRemaining,
    required this.isExhausted,
    required this.dailyAverageNeeded,
  });
}

final dailyBudgetProvider = Provider<DailyBudgetInfo>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  
  return budgetsAsync.when(
    data: (budgets) {
      if (budgets.isEmpty) {
        return DailyBudgetInfo(
          dailyAllowance: 0,
          totalRemaining: 0,
          daysRemaining: 0,
          isExhausted: false,
          dailyAverageNeeded: 0,
        );
      }

      double totalLimit = 0;
      double totalSpent = 0;

      for (var budget in budgets) {
        totalLimit += budget.limitAmount;
        totalSpent += budget.currentSpent;
      }

      final now = DateTime.now();
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysRemaining = lastDayOfMonth.day - now.day + 1; // Including today

      final remainingBudget = totalLimit - totalSpent;
      final isExhausted = remainingBudget <= 0;
      
      final allowance = isExhausted ? 0.0 : remainingBudget / daysRemaining;
      
      // Calculate daily average needed to stay within limit (if exhausted, how much to save/recover)
      // Since it's dynamic, we just return the basic info
      
      return DailyBudgetInfo(
        dailyAllowance: allowance,
        totalRemaining: remainingBudget,
        daysRemaining: daysRemaining,
        isExhausted: isExhausted,
        dailyAverageNeeded: totalLimit / lastDayOfMonth.day,
      );
    },
    loading: () => DailyBudgetInfo(dailyAllowance: 0, totalRemaining: 0, daysRemaining: 0, isExhausted: false, dailyAverageNeeded: 0),
    error: (_, __) => DailyBudgetInfo(dailyAllowance: 0, totalRemaining: 0, daysRemaining: 0, isExhausted: false, dailyAverageNeeded: 0),
  );
});
