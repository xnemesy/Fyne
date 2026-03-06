import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/transaction.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/haptics/fyne_haptics.dart';
import '../../core/theme/fyne_theme.dart';

class TransactionItem extends StatelessWidget {
  final TransactionSummary summary;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Placeholder per transazioni con decifratura fallita (HMAC mismatch / vault locked)
    if (summary.isCorrupted) {
      return _buildCorruptedPlaceholder(context);
    }

    final isIncome = summary.amount > 0;
    final absAmount = summary.amount.abs();

    // Color Logic (Matching existing design)
    Color amountColor = Theme.of(context).colorScheme.onSurface;
    if (isIncome) {
      amountColor = FyneColors.income;
    } else if (absAmount > 200) {
      amountColor = FyneColors.rust;
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
                  color: FyneColors.ink.withValues(alpha: 0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(summary.categoryColor),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getMappedIcon(summary.categoryIcon, summary.categoryName),
                size: 20,
                color: _getIconColor(summary.categoryColor),
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

  /// Riga placeholder per transazioni inaccessibili per fallimento crittografico.
  Widget _buildCorruptedPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: FyneColors.ink.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FyneColors.rust.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.lock, size: 20, color: FyneColors.rust),
          ),
          const SizedBox(width: 16),
          Text(
            'Dato protetto o non disponibile',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: FyneColors.rust.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // AI/Offline Classification Logic
  // ===============================

  Color _parseHex(String? hexColor, Color fallback) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return fallback;
    }
  }

  Color _getBackgroundColor(String? categoryColor) {
    // Sfondo dell'icona: 15% opacity del colore principale
    final baseColor = _parseHex(categoryColor, FyneColors.paperDark);
    return baseColor.withValues(alpha: 0.15);
  }

  Color _getIconColor(String? categoryColor) {
    // Colore primario dell'icona. Default verde di Fyne se mancante.
    return _parseHex(categoryColor, FyneColors.forest);
  }

  IconData _getMappedIcon(String? iconName, String? categoryName) {
    // Mapping da chiavi Material (se impostate via service) o nome categoria a Lucide
    if (iconName == 'subscriptions' || categoryName == 'Abbonamenti') return LucideIcons.refreshCw;
    if (iconName == 'shopping_cart' || categoryName == 'Alimentari') return LucideIcons.shoppingCart;
    if (iconName == 'fastfood' || categoryName == 'Fast Food') return LucideIcons.utensils;
    if (iconName == 'local_mall' || categoryName == 'Shopping') return LucideIcons.shoppingBag;
    if (iconName == 'directions_car' || categoryName == 'Trasporti') return LucideIcons.car;
    if (iconName == 'smoking_rooms' || categoryName == 'Vizi') return LucideIcons.flame;
    if (iconName == 'fitness_center' || categoryName == 'Wellness') return LucideIcons.heart;
    return LucideIcons.creditCard;
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
