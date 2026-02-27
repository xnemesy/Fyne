import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'isar_provider.dart';
import 'account_provider.dart';
import 'account_overview_provider.dart';
import 'transaction_provider.dart';

class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? error;

  SyncState({this.isSyncing = false, this.lastSyncAt, this.error});

  SyncState copyWith({bool? isSyncing, DateTime? lastSyncAt, String? error}) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => SyncState();

  Future<void> sync() async {
    if (state.isSyncing) return;

    // Legge le dipendenze PRIMA di qualsiasi await per evitare il Riverpod async-gap
    final accountNotifier   = ref.read(accountsProvider.notifier);
    final syncService       = ref.read(syncServiceProvider);

    try {
      state = state.copyWith(isSyncing: true, error: null);

      await accountNotifier.syncPendingCreates();

      final isar = await ref.read(isarProvider.future);
      await syncService.performSync(isar);

      // Guard: dopo gli await il Notifier potrebbe essere stato disposto
      try {
        ref.invalidate(accountsProvider);
        ref.invalidate(accountOverviewProvider);
        // Aggiorna anche la lista transazioni (bug #3: dati persi dopo reinstall)
        ref.invalidate(transactionsProvider);
      } catch (_) {}

      try {
        state = state.copyWith(isSyncing: false, lastSyncAt: DateTime.now());
      } catch (_) {}
    } catch (e) {
      try { state = state.copyWith(isSyncing: false, error: e.toString()); } catch (_) {}
      rethrow;
    }
  }
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
