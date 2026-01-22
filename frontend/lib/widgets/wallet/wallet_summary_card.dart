
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/wallet_provider.dart';
import '../../screens/transactions_screen.dart';

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
           color: const Color(0xFFE9E9EB).withOpacity(0.5),
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
              label: "SALDO NETTO",
              value: "${summary.netWorth.toStringAsFixed(2)} €",
              color: const Color(0xFF4A6741),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              label: "PASSIVO",
              value: "${summary.liabilities.toStringAsFixed(2)} €",
              color: const Color(0xFFA0665F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9, 
              fontWeight: FontWeight.bold, 
              color: color.withOpacity(0.6), 
              letterSpacing: 1.0
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lora( // Use Lora for harmony
              fontSize: 18, 
              fontWeight: FontWeight.w500, // Regular-ish weight
              color: const Color(0xFF1A1A1A)
            ),
          ),
        ],
      ),
    );
  }
}
