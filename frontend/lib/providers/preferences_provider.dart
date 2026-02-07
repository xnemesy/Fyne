import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesState {
  final bool milestoneAccountReached;
  final bool milestoneTransactionReached;
  final bool milestoneBudgetReached;
  final bool useBiometrics;

  PreferencesState({
    this.milestoneAccountReached = false,
    this.milestoneTransactionReached = false,
    this.milestoneBudgetReached = false,
    this.useBiometrics = false,
  });

  PreferencesState copyWith({
    bool? milestoneAccountReached,
    bool? milestoneTransactionReached,
    bool? milestoneBudgetReached,
    bool? useBiometrics,
  }) {
    return PreferencesState(
      milestoneAccountReached: milestoneAccountReached ?? this.milestoneAccountReached,
      milestoneTransactionReached: milestoneTransactionReached ?? this.milestoneTransactionReached,
      milestoneBudgetReached: milestoneBudgetReached ?? this.milestoneBudgetReached,
      useBiometrics: useBiometrics ?? this.useBiometrics,
    );
  }
}

class PreferencesNotifier extends Notifier<PreferencesState> {
  final _storage = const FlutterSecureStorage();

  @override
  PreferencesState build() {
    _load();
    return PreferencesState();
  }

  Future<void> _load() async {
    final account = await _storage.read(key: 'milestone_account') == 'true';
    final tx = await _storage.read(key: 'milestone_transaction') == 'true';
    final budget = await _storage.read(key: 'milestone_budget') == 'true';
    final biometrics = await _storage.read(key: 'biometrics_enabled') == 'true';

    state = PreferencesState(
      milestoneAccountReached: account,
      milestoneTransactionReached: tx,
      milestoneBudgetReached: budget,
      useBiometrics: biometrics,
    );
  }

  Future<void> markAccountReached() async {
    await _storage.write(key: 'milestone_account', value: 'true');
    state = state.copyWith(milestoneAccountReached: true);
  }

  Future<void> markTransactionReached() async {
    await _storage.write(key: 'milestone_transaction', value: 'true');
    state = state.copyWith(milestoneTransactionReached: true);
  }

  Future<void> markBudgetReached() async {
    await _storage.write(key: 'milestone_budget', value: 'true');
    state = state.copyWith(milestoneBudgetReached: true);
  }

  Future<void> toggleBiometrics(bool enabled) async {
    await _storage.write(key: 'biometrics_enabled', value: enabled.toString());
    state = state.copyWith(useBiometrics: enabled);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, PreferencesState>(() => PreferencesNotifier());
