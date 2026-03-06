
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/fyne_theme.dart';
import '../../../providers/budget_provider.dart';


class TopCategoriesList extends StatelessWidget {
  final List<BudgetStatus> categories;

  const TopCategoriesList({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const Text("Nessun dato disponibile");
    
    return Column(
      children: categories.take(5).map((status) {
        return _categoryRow(
          context,
          status.budget.decryptedCategoryName ?? "Sconosciuta",
          "${status.spent.toStringAsFixed(0)} €",
          status.progress,
          status.isOverBudget ? FyneColors.rust : FyneColors.forest,
        );
      }).toList(),
    );
  }

  Widget _categoryRow(BuildContext context, String label, String amount, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              Text(amount, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
