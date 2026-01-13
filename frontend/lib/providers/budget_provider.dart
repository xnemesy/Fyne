import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';

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
    return _fetchAndDecryptBudgets();
  }

  Future<List<Budget>> _fetchAndDecryptBudgets() async {
    final api = ref.read(apiServiceProvider);
    final crypto = ref.read(cryptoServiceProvider);
    final masterKey = ref.read(masterKeyProvider);

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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndDecryptBudgets());
  }
}

final budgetsProvider = AsyncNotifierProvider<BudgetNotifier, List<Budget>>(() {
  return BudgetNotifier();
});
