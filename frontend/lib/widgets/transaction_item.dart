import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'decrypted_value.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  const TransactionItem({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');

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

    final isIncome = transaction.amount > 0;
    final absAmount = transaction.amount.abs();
    
    // Color Logic
    Color amountColor = const Color(0xFF1A1A1A); // Default Small/Med Gray
    if (isIncome) {
      amountColor = const Color(0xFF2D7A5F); // Green
    } else if (absAmount > 200) {
      amountColor = const Color(0xFFA0665F); // Terra Cotta for Large
    } else if (absAmount > 50) {
      amountColor = const Color(0xFF1A1A1A).withOpacity(0.85); // Slightly darker for Med
    }

    final dateStr = DateFormat('dd MMM').format(transaction.bookingDate);
    final metaData = "$dateStr • ${transaction.categoryName ?? 'Altro'}";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8), // Increased vertical padding
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${transaction.decryptedDescription ?? 'Transazione'}${transaction.decryptedCounterParty != null && transaction.decryptedCounterParty!.isNotEmpty ? ' (${transaction.decryptedCounterParty})' : ''}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15, // Slightly larger
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metaData,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF1A1A1A).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            DecryptedValue(
              value: "${isIncome ? '+' : ''}${absAmount.toStringAsFixed(2)} €",
              style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                fontSize: 16, // Slightly larger
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
