import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final TransactionSummary summary;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key, 
    required this.summary, 
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = summary.amount > 0;
    final absAmount = summary.amount.abs();
    
    // Color Logic (Matching existing design)
    Color amountColor = const Color(0xFF1A1A1A);
    if (isIncome) {
      amountColor = const Color(0xFF2D7A5F); 
    } else if (absAmount > 200) {
      amountColor = const Color(0xFFA0665F);
    }

    final dateStr = DateFormat('dd MMM').format(summary.bookingDate);
    final categoryStr = summary.categoryName ?? 'Transazione';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9EB).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(summary.categoryName),
                size: 20,
                color: const Color(0xFF4A6741),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryStr,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$dateStr • Dato Protetto",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF1A1A1A).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${isIncome ? '+' : ''}${absAmount.toStringAsFixed(2)} €",
              style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
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
}
