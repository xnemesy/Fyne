import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'transaction_provider.dart';
import 'master_key_provider.dart';

// The master key provider is now in lib/providers/master_key_provider.dart

/**
 * Async Notifier for Budgets.
 * Fetches data from Cloud Run and decrypts it locally.
 */
class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final masterKey = ref.watch(masterKeyProvider);
    return _fetchAndDecryptBudgets(masterKey);
  }

  Future<List<Budget>> _fetchAndDecryptBudgets(dynamic masterKey) async {
    final api = ref.read(apiServiceProvider);
    final crypto = ref.read(cryptoServiceProvider);

    if (masterKey == null) return [];

    List<Budget> budgets = [];
    try {
      final response = await api.get('/api/budgets');
      final List<dynamic> jsonList = response.data;
      budgets = jsonList.map((json) => Budget.fromJson(json)).toList();

      // Decrypt names for UI display
      for (var budget in budgets) {
        try {
          if (budget.encryptedCategoryName.startsWith('mock_')) {
            budget.decryptedCategoryName = budget.encryptedCategoryName.replaceFirst('mock_', '');
          } else {
            budget.decryptedCategoryName = await crypto.decrypt(
              budget.encryptedCategoryName, 
              masterKey
            );
          }
        } catch (e) {
          budget.decryptedCategoryName = "Spesa";
        }
      }
    } catch (e) {
      debugPrint("Budget fetch error: $e");
      return [];
    }
    return budgets;
  }

  Future<void> refresh() async {
    final masterKey = ref.read(masterKeyProvider);
    state = await AsyncValue.guard(() => _fetchAndDecryptBudgets(masterKey));
  }

  Future<void> deleteBudget(String budgetId) async {
    final api = ref.read(apiServiceProvider);
    
    // 1. Snapshot previous state
    final previousState = state.value;
    if (previousState == null) return;

    // 2. Optimistic Update
    final newState = previousState.where((b) => b.id != budgetId).toList();
    state = AsyncData(newState);

    try {
      // 3. API Call
      await api.post('/api/budgets/delete', data: {'id': budgetId});
    } catch (e) {
      debugPrint("Delete budget error: $e");
      // 4. Rollback
      state = AsyncData(previousState);
    }
  }
}

final totalMonthlyBudgetProvider = StateProvider<double>((ref) => 0.0);

final dailyAllowanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final budgets = ref.watch(budgetsProvider).value ?? [];
  final stateBudget = ref.watch(totalMonthlyBudgetProvider);
  
  // Use sum of budgets if defined, else fallback to totalMonthlyBudgetProvider
  final totalBudget = budgets.isEmpty 
      ? stateBudget 
      : budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
  
  if (totalBudget <= 0) return 0.0;
  
  // Calculate total spent this month
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final spentThisMonth = transactions
      .where((tx) {
        final date = tx.bookingDate;
        return (date.isAfter(firstOfMonth) || date.isAtSameMomentAs(firstOfMonth)) && tx.amount < 0;
      })
      .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  
  final remainingBudget = totalBudget - spentThisMonth;
  
  // Days remaining in month
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = lastDayOfMonth - now.day + 1;
  
  // Safe Division & Edge Cases
  if (daysRemaining <= 0) {
    // If it's the last day (or calculation anomaly), all remaining budget is available today.
    // Clamp to 0 to avoid negative allowance if overbudget.
    return remainingBudget < 0 ? 0.0 : remainingBudget;
  }
  
  final daily = remainingBudget / daysRemaining;
  
  // Return 0 if negative (overbudget), otherwise the calculated daily amount
  return daily < 0 ? 0.0 : daily;
});

final budgetsProvider = AsyncNotifierProvider<BudgetNotifier, List<Budget>>(() {
  return BudgetNotifier();
});

class BudgetStatus {
  final Budget budget;
  final double spent;
  BudgetStatus({required this.budget, required this.spent});

  double get progress => budget.limitAmount > 0 ? (spent / budget.limitAmount) : 0;
  double get remaining => budget.limitAmount - spent;
  bool get isOverBudget => spent > budget.limitAmount;
}

final budgetSummaryProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? [];
  final transactions = ref.watch(transactionsProvider).value ?? [];
  
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  
  return budgets.map((budget) {
    final categorySpent = transactions
        .where((tx) => 
          tx.categoryUuid == budget.categoryUuid && 
          tx.bookingDate.isAfter(firstOfMonth) &&
          tx.amount < 0)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
        
    return BudgetStatus(budget: budget, spent: categorySpent);
  }).toList();
});
