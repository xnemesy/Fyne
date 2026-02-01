import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../providers/isar_provider.dart';
import '../../services/crypto_service.dart';
import '../../providers/master_key_provider.dart';

/// Provider for the Transaction Repository
final transactionRepositoryProvider = Provider<TransactionRepository?>((ref) {
  final isar = ref.watch(isarProvider).value;
  final crypto = ref.watch(cryptoServiceProvider);
  final masterKey = ref.watch(masterKeyProvider);
  
  if (isar == null || masterKey == null) return null;
  
  return TransactionRepository(isar, crypto, masterKey);
});

/// Fetches a specific page of transaction summaries (Decrypted in isolate)
final transactionsPageProvider = FutureProvider.family<List<TransactionSummary>, int>((ref, page) async {
  final repo = ref.read(transactionRepositoryProvider);
  if (repo == null) return [];
  
  // 1. Fetch encrypted items (Instant)
  final encrypted = await repo.getEncryptedPage(page: page);
  
  // 2. Decrypt in isolate (Non-blocking)
  return await repo.decryptPageForList(encrypted);
});

/// Detailed Transaction decryption (On-demand)
final transactionDetailProvider = FutureProvider.family<TransactionModel?, String>((ref, uuid) async {
  final repo = ref.read(transactionRepositoryProvider);
  if (repo == null) return null;
  
  return await repo.getByUuid(uuid);
});

/// Main Notifier to manage infinite scroll state
class TransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionSummary>>> {
  final Ref ref;
  int _currentPage = 0;
  bool _hasMore = true;

  TransactionsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading && _currentPage > 0) return;

    try {
      final newItems = await ref.read(transactionsPageProvider(_currentPage).future);
      
      if (newItems.isEmpty) {
        _hasMore = false;
        if (_currentPage == 0) state = const AsyncValue.data([]);
      } else {
        _currentPage++;
        final currentList = state.valueOrNull ?? [];
        state = AsyncValue.data([...currentList, ...newItems]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final transactionsNotifierProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<TransactionSummary>>>((ref) {
  return TransactionsNotifier(ref);
});
