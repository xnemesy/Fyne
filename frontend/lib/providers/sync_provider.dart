import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'isar_provider.dart';
import 'account_provider.dart';

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

  Ref get _ref => ref;

  Future<void> sync() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      await _ref.read(accountsProvider.notifier).syncPendingCreates();

      final isar = await _ref.read(isarProvider.future);
      final syncService = _ref.read(syncServiceProvider);

      await syncService.performSync(isar);

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
