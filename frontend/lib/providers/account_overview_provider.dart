import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:isar_community/isar.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/crypto_service.dart';
import 'isar_provider.dart';
import 'master_key_provider.dart';
import 'auth_provider.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/crypto_log.dart';

/// Stato completo dell'overview finanziaria
class AccountOverviewState {
  final List<AccountSummary> accounts;
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double netCashFlow;
  final bool isLoading;
  final String? error;

  AccountOverviewState({
    this.accounts = const [],
    this.totalBalance = 0.0,
    this.monthlyIncome = 0.0,
    this.monthlyExpenses = 0.0,
    this.netCashFlow = 0.0,
    this.isLoading = false,
    this.error,
  });

  AccountOverviewState copyWith({
    List<AccountSummary>? accounts,
    double? totalBalance,
    double? monthlyIncome,
    double? monthlyExpenses,
    double? netCashFlow,
    bool? isLoading,
    String? error,
  }) {
    return AccountOverviewState(
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      netCashFlow: netCashFlow ?? this.netCashFlow,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Dati riassuntivi per un singolo account
class AccountSummary {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final AccountType type;
  final String group;
  /// true se la decifratura AES-GCM è fallita per questo account.
  /// L'UI mostra un placeholder "Dato protetto o non disponibile".
  final bool isCorrupted;

  AccountSummary({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.type,
    required this.group,
    this.isCorrupted = false,
  });
}

class AccountOverviewNotifier extends StateNotifier<AccountOverviewState> {
  final Ref ref;
  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;

  AccountOverviewNotifier(this.ref) : super(AccountOverviewState()) {
    _init();
  }

  @override
  void dispose() {
    _accountsSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (!mounted) return;
    final isar = await ref.read(isarProvider.future);
    if (!mounted) return;

    // Listen to account changes to keep total balance up to date
    _accountsSub = isar.accounts.where().isDeletedEqualTo(false).watch(fireImmediately: true).listen((_) {
      if (mounted) refresh();
    });

    // Listen to transactions to keep monthly income/expenses up to date
    _transactionsSub = isar.transactionModels.where().watch().listen((_) {
      if (mounted) refresh();
    });
  }

  /// Refresh completo di tutti i dati
  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cattura tutte le dipendenze ref PRIMA di qualsiasi await (anti async-gap)
      final masterKey = ref.read(masterKeyProvider);
      final authStatus = ref.read(authProvider).status;
      final cryptoService = ref.read(cryptoServiceProvider);
      final masterKeyNotifier = ref.read(masterKeyProvider.notifier);
      final isar = await ref.read(isarProvider.future);
      if (!mounted) return;

      if (masterKey == null) {
        // P0 FIX: If vault is locked but user is authenticated, attempt auto-unlock
        if (authStatus == AuthStatus.authenticated ||
            authStatus == AuthStatus.locked) {
          debugPrint(
              "🔐 [OVERVIEW] MasterKey NULL but status is Authenticated/Locked. Attempting background recovery...");
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          final masterKeyRetry = masterKeyNotifier.state;
          if (masterKeyRetry == null) {
            debugPrint(
                "🔐 [OVERVIEW] Background recovery failed. Showing empty state.");
            state = state.copyWith(
                isLoading: false, accounts: [], totalBalance: 0.0);
            return;
          }
        } else {
          state =
              state.copyWith(isLoading: false, accounts: [], totalBalance: 0.0);
          return;
        }
      }

      // 1. Carica tutti gli account cifrati non marcati come cancellati
      final encryptedAccounts = await isar.accounts.where().isDeletedEqualTo(false).findAll();
      final accountSummaries = <AccountSummary>[];
      double totalBal = 0.0;

      for (final acc in encryptedAccounts) {
        try {
          final decryptedName = await cryptoService.decrypt(acc.encryptedName,
              scope: EncryptionScope.database,
              version: acc.encryptionVersion,
              type: 'account_name');
          final decryptedBalance = await cryptoService.decrypt(
              acc.encryptedBalance,
              scope: EncryptionScope.database,
              version: acc.encryptionVersion,
              type: 'account_balance');
          final balance = double.tryParse(decryptedBalance) ?? 0.0;

          accountSummaries.add(AccountSummary(
            id: acc.id,
            name: decryptedName,
            balance: balance,
            currency: acc.currency,
            type: acc.type,
            group: acc.group,
          ));

          totalBal += balance;
        } catch (e) {
          // Registra il fallimento crittografico e inserisce un placeholder visibile in UI
          CryptoLog.record(component: 'account_overview', entityId: acc.id, error: e);
          accountSummaries.add(AccountSummary(
            id: acc.id,
            name: 'Conto non accessibile',
            balance: 0.0,
            currency: acc.currency,
            type: acc.type,
            group: acc.group,
            isCorrupted: true,
          ));
        }
      }

      // 3. Calcola statistiche mensili dalle transazioni
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final monthlyTransactions = await isar.transactionModels
          .where()
          .bookingDateBetween(startOfMonth, now)
          .findAll();

      double income = 0.0;
      double expenses = 0.0;

      for (final tx in monthlyTransactions) {
        try {
          final amountStr = await cryptoService.decrypt(tx.encryptedAmount,
              scope: EncryptionScope.database,
              version: tx.encryptionVersion,
              type: 'transaction_amount');
          final amount = double.tryParse(amountStr) ?? 0.0;

          if (amount > 0) {
            income += amount;
          } else {
            expenses += amount.abs();
          }
        } catch (e) {
          // Registra il fallimento crittografico della transazione mensile
          CryptoLog.record(component: 'account_overview_tx', entityId: tx.uuid, error: e);
        }
      }

      if (!mounted) return;
      state = AccountOverviewState(
        accounts: accountSummaries,
        totalBalance: totalBal,
        monthlyIncome: income,
        monthlyExpenses: expenses,
        netCashFlow: income - expenses,
        isLoading: false,
      );
    } catch (e, stack) {
      debugPrint('❌ Errore refresh overview: $e\n$stack');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Aggiorna il balance di un singolo account
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final masterKey = ref.read(masterKeyProvider);
      if (masterKey == null) return;
      final cryptoService = ref.read(cryptoServiceProvider);

      final isar = await ref.read(isarProvider.future);

      final account =
          await isar.accounts.where().idEqualTo(accountId).findFirst();
      if (account == null) return;
      final encryptedBalance = await cryptoService.encrypt(
        newBalance.toString(),
        scope: EncryptionScope.database,
        type: 'account_balance',
      );

      await isar.writeTxn(() async {
        final updated = Account(
          id: account.id,
          encryptedName: account.encryptedName,
          encryptedBalance: encryptedBalance,
          currency: account.currency,
          type: account.type,
          providerId: account.providerId,
          group: account.group,
          updatedAt: DateTime.now(),
        );
        await isar.accounts.put(updated);
      });

      // Refresh overview
      await refresh();
    } catch (e) {
      debugPrint('❌ Errore aggiornamento balance: $e');
    }
  }

  /// Filtra accounts per tipo
  List<AccountSummary> getAccountsByType(AccountType type) {
    return state.accounts.where((a) => a.type == type).toList();
  }

  /// Filtra accounts per gruppo
  List<AccountSummary> getAccountsByGroup(String group) {
    return state.accounts.where((a) => a.group == group).toList();
  }

  /// Calcola totale per tipo di account
  double getTotalByType(AccountType type) {
    return state.accounts
        .where((a) => a.type == type)
        .fold(0.0, (sum, a) => sum + a.balance);
  }
}

final accountOverviewProvider =
    StateNotifierProvider<AccountOverviewNotifier, AccountOverviewState>(
  (ref) => AccountOverviewNotifier(ref),
);
