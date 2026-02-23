import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'isar_provider.dart';
import 'account_provider.dart';
import 'account_overview_provider.dart';

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

    state = state.copyWith(isSyncing: true, error: null);

    try {
      // Sincronizza i conti pendenti (create locali non ancora su Firestore)
      await ref.read(accountsProvider.notifier).syncPendingCreates();

      final isar = await ref.read(isarProvider.future);
      final syncService = ref.read(syncServiceProvider);

      await syncService.performSync(isar);

      // Fix Bug 3: dopo il pull dei dati cloud, invalida i provider
      // così la UI mostra immediatamente i conti scaricati
      ref.invalidate(accountsProvider);
      ref.invalidate(accountOverviewProvider);

      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
      rethrow;
    }
  }
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
