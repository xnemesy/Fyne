import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:isar_community/isar.dart';
import '../models/transaction.dart';
import '../data/repositories/transaction_repository.dart';
import 'isar_provider.dart';
import '../services/crypto_service.dart';
import '../services/key_rotation_service.dart';

/// Provider for the Transaction Repository
final transactionRepositoryProvider = Provider<TransactionRepository?>((ref) {
  final isar = ref.watch(isarProvider).value;
  final crypto = ref.watch(cryptoServiceProvider);
  final rotation = ref.watch(keyRotationProvider);

  if (isar == null) return null;

  return TransactionRepository(isar, crypto, rotation);
});

/// Fetches a specific page of transaction summaries (Decrypted in Isolate — 60fps)
final transactionsPageProvider =
    FutureProvider.family<List<TransactionSummary>, int>((ref, page) async {
  final repo = ref.watch(transactionRepositoryProvider);
  if (repo == null) {
    return <TransactionSummary>[];
  }

  // 1. Fetch encrypted items (Istantaneo — no CPU)
  final encrypted = await repo.getEncryptedPage(page: page);

  // 2. Decifra in Isolate separato (non blocca il main thread → 60fps)
  return await repo.decryptPageInIsolate(encrypted);
});

/// Detailed Transaction decryption (On-demand)
final transactionDetailProvider =
    FutureProvider.family<TransactionModel?, String>((ref, uuid) async {
  final repo = ref.watch(transactionRepositoryProvider);
  if (repo == null) return null;

  return await repo.getByUuid(uuid);
});

/// Main Notifier to manage infinite scroll state
class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<TransactionSummary>>> {
  final Ref ref;
  int _currentPage = 0;
  bool _hasMore = true;

  TransactionsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    ref.invalidate(transactionsPageProvider);
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading && _currentPage > 0) return;

    try {
      final newItems = await ref
          .read(transactionsPageProvider(_currentPage).future)
          .timeout(const Duration(seconds: 10)); // Reduced timeout for better UX

      if (newItems.isEmpty) {
        _hasMore = false;
        if (_currentPage == 0) {
          state = const AsyncValue.data([]);
        } else {
          // Force UI to stop showing the bottom spinner by updating state identically
          final currentList = state.value ?? <TransactionSummary>[];
          state = AsyncValue.data(currentList);
        }
      } else {
        // Purge automatico dei record irrecuperabili (chiave precedente / HMAC mismatch)
        final corruptedUuids = newItems
            .where((s) => s.isCorrupted)
            .map((s) => s.uuid)
            .toList();
        if (corruptedUuids.isNotEmpty) {
          final repo = ref.read(transactionRepositoryProvider);
          repo?.purgeOrphansByUuids(corruptedUuids);
        }
        final validItems = newItems.where((s) => !s.isCorrupted).toList();

        _currentPage++;
        final currentList = state.value ?? <TransactionSummary>[];
        state = AsyncValue.data([...currentList, ...validItems]);
      }
    } catch (e, stack) {
      debugPrint("Transactions loadMore error: $e\n$stack");
      if (_currentPage == 0) {
        // First page failed — show empty state or fallback, not infinite spinner
        state = const AsyncValue.data([]);
      } else {
        // Show error but keep existing data 
        state = AsyncValue<List<TransactionSummary>>.error(e, stack).copyWithPrevious(state);
      }
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> exportToCsv() async {
    final repo = ref.read(transactionRepositoryProvider);
    if (repo == null) return;

    final isar = ref.read(isarProvider).value;
    if (isar == null) return;

    // 1. Fetch ALL transactions (encrypted)
    final allEncrypted = await isar.transactionModels.where().findAll();

    // 2. Decrypt ALL (Isolate)
    final decrypted = await repo.decryptPageForList(allEncrypted);

    // 3. User ExportService to handle auth and CSV creation
    // To avoid dependency loops, we can use a provider for ExportService
    // final exportService = ExportService();
    // exportService.exportToCsv(decrypted.map((e) => {
    //   'bookingDate': e.bookingDate,
    //   'decryptedDescription': e.description,
    //   'amount': e.amount,
    //   'decryptedCategory': e.categoryName,
    // }).toList());

    print("Export requested for ${decrypted.length} items");
  }

  Future<void> addTransaction(
    TransactionModel tx, {
    String? rawAmount,
    String? rawDesc,
    String? rawCounterParty,
    String? rawCategoryName,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    if (repo == null) {
      throw StateError('Transaction repository non inizializzato');
    }

    await repo.save(
      tx,
      rawAmount: rawAmount ?? tx.amount?.toString(),
      rawDesc: rawDesc ?? tx.description,
      rawCounterParty: rawCounterParty ?? tx.counterParty,
      rawCategoryName: rawCategoryName ?? tx.categoryName,
    );
    ref.invalidate(transactionsPageProvider);
    ref.invalidate(transactionDetailProvider);
    ref.invalidate(monthlySpentProvider);
    await refresh();
  }

  Future<TransactionModel?> deleteTransaction(String uuid) async {
    final repo = ref.read(transactionRepositoryProvider);
    if (repo == null) {
      throw StateError('Transaction repository non inizializzato');
    }

    final existing = await repo.getByUuid(uuid);
    await repo.deleteByUuid(uuid);
    ref.invalidate(transactionsPageProvider);
    ref.invalidate(transactionDetailProvider);
    ref.invalidate(monthlySpentProvider);
    await refresh();
    return existing;
  }
}

final transactionsNotifierProvider = StateNotifierProvider<TransactionsNotifier,
    AsyncValue<List<TransactionSummary>>>((ref) {
  return TransactionsNotifier(ref);
});

final transactionsProvider = transactionsNotifierProvider;

/// Provider for total spent in the current month (Accurate, not paginated)
final monthlySpentProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  if (repo == null) return 0.0;

  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return await repo.getTotalSpentInRange(firstOfMonth, endOfMonth);
});
