
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/fyne_theme.dart';
import '../../../providers/wallet_provider.dart';

/// Card "Saldo Netto / Passivo" nella WalletScreen.
/// Fix Bug 1: usa colori del tema invece di Colors.white hardcoded.
class WalletSummaryCard extends ConsumerWidget {
  const WalletSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(walletSummaryProvider);

    if (summary.isLoading) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Fix Bug 1: tema-aware invece di Color(0xFFE9E9EB) hardcoded
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              context: context,
              label: "SALDO NETTO",
              value: "${summary.netWorth.toStringAsFixed(2)} €",
              accentColor: FyneColors.forest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              context: context,
              label: "PASSIVO",
              value: "${summary.liabilities.toStringAsFixed(2)} €",
              accentColor: FyneColors.rust,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        // Fix Bug 1: sfondo coerente con il tema (chiaro/scuro)
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              // Fix Bug 1: colore label tema-aware
              color: accentColor.withValues(alpha:0.7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              // Fix Bug 1: testo sempre leggibile in dark/light mode
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
