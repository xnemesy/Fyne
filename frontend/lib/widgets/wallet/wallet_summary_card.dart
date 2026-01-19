
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text("SALDO NETTO (EUR)", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4A6741), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text("${summary.netWorth.toStringAsFixed(2)} €", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.black.withOpacity(0.05)),
                Expanded(
                  child: Column(
                    children: [
                      Text("PASSIVO (EUR)", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4A6741), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text("${summary.liabilities.toStringAsFixed(2)} €", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 0, endIndent: 0),
          ListTile(
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
            },
            dense: true,
            leading: const Icon(LucideIcons.list, size: 18, color: Color(0xFF1A1A1A)),
            title: Text("Tutte le transazioni", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }
}
