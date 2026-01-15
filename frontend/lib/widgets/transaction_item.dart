import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'decrypted_value.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final dateFormat = DateFormat('dd MMM');

    IconData getIcon() {
      switch (transaction.categoryName) {
        case 'Alimentari': return LucideIcons.shoppingCart;
        case 'Wellness': return LucideIcons.heart;
        case 'Shopping': return LucideIcons.shoppingBag;
        case 'Trasporti': return LucideIcons.car;
        case 'Abbonamenti': return LucideIcons.refreshCw;
        case 'Vizi': return LucideIcons.flame;
        case 'Fast Food': return LucideIcons.utensils;
        default: return LucideIcons.creditCard;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBF9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(getIcon(), size: 18, color: const Color(0xFF4A6741)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.decryptedDescription ?? "Transazione",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${dateFormat.format(transaction.bookingDate)} • ${transaction.categoryName ?? 'Altro'}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1A1A1A).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          DecryptedValue(
            value: "${transaction.amount > 0 ? '+' : ''}${transaction.amount.abs().toStringAsFixed(2)}",
            style: GoogleFonts.lora(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: transaction.amount > 0 ? const Color(0xFF4A6741) : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
