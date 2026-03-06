import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar_community/isar.dart';
import '../models/budget.dart';
import '../services/crypto_service.dart';
import '../services/key_rotation_service.dart';
import 'isar_provider.dart';
import 'dart:convert';
import 'transaction_provider.dart';

class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final isar = await ref.watch(isarProvider.future);

    // Watch Isar for changes
    final sub = isar.budgets.where().isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .listen((budgets) async {
      await _processBudgets(budgets);
      if (ref.mounted) state = AsyncData(budgets);
    });

    // Cancel stream on provider dispose to avoid memory leak
    ref.onDispose(sub.cancel);

    return _fetchAndProcessBudgets(isar);
  }

  Future<List<Budget>> _fetchAndProcessBudgets(Isar isar) async {
    final budgets = await isar.budgets.where().isDeletedEqualTo(false).findAll();
    await _processBudgets(budgets);
    return budgets;
  }

  Future<void> _processBudgets(List<Budget> budgets) async {
    final crypto = ref.read(cryptoServiceProvider);
    final rotation = ref.read(keyRotationProvider);
    final isar = await ref.read(isarProvider.future);

    for (var i = 0; i < budgets.length; i++) {
      final budget = budgets[i];
      
      // 1. Lazy Migration
      final migrated = await rotation.migrateIfLegacy<Budget>(
        recordUuid: budget.id,
        currentVersion: budget.encryptionVersion,
        decryptFn: (v) async {
          final catName = await crypto.decrypt(budget.encryptedCategoryName, scope: EncryptionScope.database, type: 'budget_category', version: v);
          return jsonEncode({'categoryName': catName});
        },
        reEncryptAndUpdateFn: (plain, v) async {
          final data = jsonDecode(plain);
          final newCatName = await crypto.encrypt(data['categoryName'], scope: EncryptionScope.database, type: 'budget_category', version: v);
          
          return await isar.writeTxn(() async {
            final existing = await isar.budgets.where().idEqualTo(budget.id).findFirst();
            if (existing == null) throw Exception('Record lost');
            
            final updated = Budget(
              id: existing.id,
              categoryUuid: existing.categoryUuid,
              encryptedCategoryName: newCatName,
              limitAmount: existing.limitAmount,
              currentSpent: existing.currentSpent,
              updatedAt: DateTime.now(),
              isDeleted: existing.isDeleted,
              encryptionVersion: v,
            );
            await isar.budgets.put(updated);
            return updated;
          });
        },
      );

      final active = migrated ?? budget;
      if (migrated != null) budgets[i] = migrated;

      // 2. Standard Decryption
      try {
        active.decryptedCategoryName = await crypto.decrypt(active.encryptedCategoryName, scope: EncryptionScope.database, type: 'budget_category', version: active.encryptionVersion);
      } catch (e) {
        active.decryptedCategoryName = "Budget Criptato [v${active.encryptionVersion}]";
      }
    }
  }

  Future<void> saveBudget(Budget budget) async {
    final isar = await ref.read(isarProvider.future);
    final updatedBudget = Budget(
      id: budget.id,
      categoryUuid: budget.categoryUuid,
      encryptedCategoryName: budget.encryptedCategoryName,
      limitAmount: budget.limitAmount,
      currentSpent: budget.currentSpent,
      updatedAt: DateTime.now(),
      isDeleted: false,
    );

    await isar.writeTxn(() => isar.budgets.put(updatedBudget));
    ref.invalidateSelf();
  }

  Future<void> deleteBudget(String budgetId) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final existing = await isar.budgets.where().idEqualTo(budgetId).findFirst();
      if (existing != null) {
        final deletedBudget = Budget(
          id: existing.id,
          categoryUuid: existing.categoryUuid,
          encryptedCategoryName: existing.encryptedCategoryName,
          limitAmount: existing.limitAmount,
          currentSpent: existing.currentSpent,
          updatedAt: DateTime.now(),
          isDeleted: true,
        );
        await isar.budgets.put(deletedBudget);
      }
    });
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final totalMonthlyBudgetProvider = StateProvider<double>((ref) => 0.0);

final dailyAllowanceProvider = Provider<double>((ref) {
  final monthlySpentAsync = ref.watch(monthlySpentProvider);
  final budgets = ref.watch(budgetsProvider).value ?? [];
  final stateBudget = ref.watch(totalMonthlyBudgetProvider);
  
  // Use sum of budgets if defined, else fallback to totalMonthlyBudgetProvider
  final totalBudget = budgets.isEmpty 
      ? stateBudget 
      : budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
  
  if (totalBudget <= 0) return 0.0;
  
  // Calculate total spent this month using the accurate provider
  final spentThisMonth = monthlySpentAsync.value ?? 0.0;
  
  final remainingBudget = totalBudget - spentThisMonth;
  
  // Days remaining in month
  final now = DateTime.now();
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = lastDayOfMonth - now.day + 1;
  
  if (daysRemaining <= 0) {
    return remainingBudget < 0 ? 0.0 : remainingBudget;
  }
  
  final daily = remainingBudget / daysRemaining;
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

/// Spesa del mese corrente aggregata per categoryUuid.
/// Usa il repository direttamente (non la lista paginata) per precisione totale.
/// Si aggiorna automaticamente quando cambia `transactionsProvider`.
final monthlyCategorySpentProvider = FutureProvider<Map<String, double>>((ref) async {
  // Ascolta i cambiamenti della lista paginata per triggherare il ricalcolo
  ref.watch(transactionsProvider);

  final repo = ref.watch(transactionRepositoryProvider);
  if (repo == null) return {};

  final now          = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth   = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return repo.getSpentByCategoriesInRange(firstOfMonth, endOfMonth);
});

final budgetSummaryProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets       = ref.watch(budgetsProvider).value ?? [];
  // Usa i dati precisi dal repository; fallback {} durante il caricamento
  final categorySpent = ref.watch(monthlyCategorySpentProvider).value ?? {};

  return budgets.map((budget) {
    final spent = categorySpent[budget.categoryUuid] ?? 0.0;
    return BudgetStatus(budget: budget, spent: spent);
  }).toList();
});
