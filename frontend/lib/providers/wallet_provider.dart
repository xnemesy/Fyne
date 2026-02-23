
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'account_provider.dart';
import '../services/currency_service.dart';

/// Fix Bug 2: rimosso il calcolo delle ScheduledTransaction dal passivo.
/// Solo i saldi reali dei conti (assets/liabilities) concorrono al calcolo.
/// Se non ci sono conti → WalletSummary.empty(), zero fantasmi.
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
      // Fix Bug 2: se non ci sono conti, ritorno diretto a zero senza calcoli
      if (accounts.isEmpty) return WalletSummary.empty();

      double assets = 0;
      double liabilities = 0;

      // Calcolo basato solo sui saldi reali dei conti cifrati
      for (var acc in accounts) {
        final balStr = acc.decryptedBalance?.replaceAll(',', '.') ?? '0';
        final double bal = double.tryParse(balStr) ?? 0;
        final double balInEur = currencyService.convertToEur(bal, acc.currency);

        if (balInEur >= 0) {
          assets += balInEur;
        } else {
          // Fix Bug 2: solo saldi negativi dei conti reali vanno nel passivo,
          // NON le ScheduledTransaction (quelle sono impegni futuri, non debiti)
          liabilities += balInEur.abs();
        }
      }

      return WalletSummary(
        netWorth: assets - liabilities,
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
