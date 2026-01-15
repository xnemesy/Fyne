import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'transaction_provider.dart';

// Service providers
final apiServiceProvider = Provider((ref) => ApiService());
final cryptoServiceProvider = Provider((ref) => CryptoService());

// The master key provider (in a real app, this is derived once at login and kept in secure memory)
final masterKeyProvider = StateProvider<dynamic>((ref) => null);

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

    final response = await api.get('/api/budgets');
    final List<dynamic> data = response.data;
    
    final List<Budget> budgets = data.map((json) => Budget.fromJson(json)).toList();

    // Decrypt names for UI display
    for (var budget in budgets) {
      try {
        budget.decryptedCategoryName = await crypto.decrypt(
          budget.encryptedCategoryName, 
          masterKey
        );
      } catch (e) {
        budget.decryptedCategoryName = "Encrypted Category";
      }
    }

    return budgets;
  }

  Future<void> refresh() async {
    final masterKey = ref.read(masterKeyProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndDecryptBudgets(masterKey));
  }
}

final totalMonthlyBudgetProvider = StateProvider<double>((ref) => 2500.0); // Example budget

final dailyAllowanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final budgets = ref.watch(budgetsProvider).value ?? [];
  final stateBudget = ref.watch(totalMonthlyBudgetProvider);
  
  // Use sum of budgets if defined, else fallback to totalMonthlyBudgetProvider
  final totalBudget = budgets.isEmpty 
      ? stateBudget 
      : budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
  
  // Calculate total spent this month
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final spentThisMonth = transactions
      .where((tx) => tx.bookingDate.isAfter(firstOfMonth))
      .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  
  final remainingBudget = totalBudget - spentThisMonth;
  
  // Days remaining in month
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = lastDayOfMonth - now.day + 1;
  
  if (daysRemaining <= 0) return remainingBudget;
  return remainingBudget / daysRemaining;
});

final budgetsProvider = AsyncNotifierProvider<BudgetNotifier, List<Budget>>(() {
  return BudgetNotifier();
});
