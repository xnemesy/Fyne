
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import 'account_provider.dart';
import 'scheduled_provider.dart';
import '../services/currency_service.dart';

class WalletSummary {
  final double netWorth;
  final double liabilities;
  final double assets;
  final int totalAccounts;
  final bool isLoading;

  WalletSummary({
    required this.netWorth,
    required this.liabilities,
    required this.assets,
    required this.totalAccounts,
    required this.isLoading,
  });

  factory WalletSummary.empty() {
    return WalletSummary(
      netWorth: 0,
      liabilities: 0,
      assets: 0,
      totalAccounts: 0,
      isLoading: false,
    );
  }

  factory WalletSummary.loading() {
    return WalletSummary(
      netWorth: 0,
      liabilities: 0,
      assets: 0,
      totalAccounts: 0,
      isLoading: true,
    );
  }
}

final walletSummaryProvider = Provider<WalletSummary>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final scheduledAsync = ref.watch(scheduledProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  return accountsAsync.when(
    data: (accounts) {
      double assets = 0;
      double liabilities = 0;

      // 1. Calculate from balances
      for (var acc in accounts) {
        final balStr = acc.decryptedBalance?.replaceAll(',', '.') ?? '0';
        double bal = double.tryParse(balStr) ?? 0;
        double balInEur = currencyService.convertToEur(bal, acc.currency);
        
        if (balInEur >= 0) {
          assets += balInEur;
        } else {
          liabilities += balInEur.abs();
        }
      }

      // 2. Add future expenses from Vault (Scheduled Transactions)
      final scheduled = scheduledAsync.value ?? [];
      for (var tx in scheduled) {
        // We only add expenses (negative amounts or assumed debt) to liabilities
        // Assuming scheduled transactions with amount > 0 are income (not liabilities)
        if (tx.amount < 0) {
          // Scheduled amounts are usually in EUR or primary currency, 
          // but we apply conversion to be safe if model supports it.
          // For now, ScheduledTransaction model uses double amount directly.
          liabilities += tx.amount.abs();
        }
      }

      double netWorth = assets - liabilities;

      return WalletSummary(
        netWorth: netWorth,
        assets: assets,
        liabilities: liabilities,
        totalAccounts: accounts.length,
        isLoading: false,
      );
    },
    error: (_, __) => WalletSummary.empty(),
    loading: () => WalletSummary.loading(),
  );
});
