
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import 'account_provider.dart';
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
  final currencyService = ref.watch(currencyServiceProvider);

  return accountsAsync.when(
    data: (accounts) {
      double netWorth = 0;
      double liabilities = 0;
      double assets = 0;

      for (var acc in accounts) {
        final balStr = acc.decryptedBalance?.replaceAll(',', '.') ?? '0';
        double bal = double.tryParse(balStr) ?? 0;
        
        // Convert to EUR
        double balInEur = currencyService.convertToEur(bal, acc.currency);
        
        if (balInEur >= 0) {
          assets += balInEur;
        } else {
          liabilities += balInEur.abs();
        }
      }
      netWorth = assets - liabilities; // liabilities are positive magnitude here

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
