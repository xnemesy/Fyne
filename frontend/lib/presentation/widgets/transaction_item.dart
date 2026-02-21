import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/transaction.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/haptics/fyne_haptics.dart';

class TransactionItem extends StatelessWidget {
  final TransactionSummary summary;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = summary.amount > 0;
    final absAmount = summary.amount.abs();

    // Color Logic (Matching existing design)
    Color amountColor = Theme.of(context).colorScheme.onSurface;
    if (isIncome) {
      amountColor = const Color(0xFF2D7A5F);
    } else if (absAmount > 200) {
      amountColor = const Color(0xFFA0665F);
    }

    final dateStr = FyneDateFormatter.formatFull(summary.bookingDate);
    final titleStr = _displayTitle;
    final categoryStr = summary.categoryName ?? 'Non categorizzato';

    return InkWell(
      onTap: () {
        FyneHaptics.onTransactionTap();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9EB).withValues(alpha: 0.5),
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
                    titleStr,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$dateStr • $categoryStr",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${isIncome ? '+' : '-'}${FyneCurrencyFormatter.format(absAmount)} €",
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
      case 'Alimentari':
        return LucideIcons.shoppingCart;
      case 'Wellness':
        return LucideIcons.heart;
      case 'Shopping':
        return LucideIcons.shoppingBag;
      case 'Trasporti':
        return LucideIcons.car;
      case 'Abbonamenti':
        return LucideIcons.refreshCw;
      case 'Vizi':
        return LucideIcons.flame;
      case 'Fast Food':
        return LucideIcons.utensils;
      default:
        return LucideIcons.creditCard;
    }
  }

  String get _displayTitle {
    final desc =
        (summary.description == null || summary.description!.trim().isEmpty)
            ? 'Transazione'
            : summary.description!.trim();
    final beneficiary = summary.counterParty?.trim();
    if (beneficiary != null && beneficiary.isNotEmpty) {
      return '$desc $beneficiary';
    }
    return desc;
  }
}
