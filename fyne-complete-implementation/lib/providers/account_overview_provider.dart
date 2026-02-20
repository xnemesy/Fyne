import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/crypto_service.dart';
import 'isar_provider.dart';
import 'master_key_provider.dart';

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

  AccountSummary({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.type,
    required this.group,
  });
}

class AccountOverviewNotifier extends StateNotifier<AccountOverviewState> {
  final Ref ref;
  
  AccountOverviewNotifier(this.ref) : super(AccountOverviewState()) {
    _init();
  }

  Future<void> _init() async {
    await refresh();
  }

  /// Refresh completo di tutti i dati
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isar = await ref.read(isarProvider.future);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) {
        throw Exception('Master key non disponibile');
      }

      // 1. Carica tutti gli account cifrati
      final encryptedAccounts = await isar.accounts.where().findAll();
      
      // 2. Decifra in parallelo
      final cryptoService = CryptoService();
      final accountSummaries = <AccountSummary>[];
      double totalBal = 0.0;

      for (final acc in encryptedAccounts) {
        try {
          final decryptedName = await cryptoService.decrypt(acc.encryptedName, masterKey);
          final decryptedBalance = await cryptoService.decrypt(acc.encryptedBalance, masterKey);
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
          // Log ma continua con gli altri account
          print('⚠️ Errore decifratura account ${acc.id}: $e');
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
          final amountStr = await cryptoService.decrypt(tx.encryptedAmount, masterKey);
          final amount = double.tryParse(amountStr) ?? 0.0;
          
          if (amount > 0) {
            income += amount;
          } else {
            expenses += amount.abs();
          }
        } catch (e) {
          print('⚠️ Errore decifratura transazione ${tx.uuid}: $e');
        }
      }

      state = AccountOverviewState(
        accounts: accountSummaries,
        totalBalance: totalBal,
        monthlyIncome: income,
        monthlyExpenses: expenses,
        netCashFlow: income - expenses,
        isLoading: false,
      );
    } catch (e, stack) {
      print('❌ Errore refresh overview: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Aggiorna il balance di un singolo account
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final masterKey = ref.read(masterKeyProvider);
      if (masterKey == null) return;

      final account = await isar.accounts.where().idEqualTo(accountId).findFirst();
      if (account == null) return;

      final cryptoService = CryptoService();
      final encryptedBalance = await cryptoService.encrypt(
        newBalance.toString(),
        masterKey,
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
        );
        await isar.accounts.put(updated);
      });

      // Refresh overview
      await refresh();
    } catch (e) {
      print('❌ Errore aggiornamento balance: $e');
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

final accountOverviewProvider = StateNotifierProvider<AccountOverviewNotifier, AccountOverviewState>(
  (ref) => AccountOverviewNotifier(ref),
);
