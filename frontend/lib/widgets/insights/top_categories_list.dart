
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/budget.dart';

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
          status.budget.decryptedCategoryName ?? "Sconosciuta",
          "${status.spent.toStringAsFixed(0)} €",
          status.progress,
          status.isOverBudget ? const Color(0xFFD63031) : const Color(0xFF4A6741),
        );
      }).toList(),
    );
  }

  Widget _categoryRow(String label, String amount, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              Text(amount, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF2F2F0),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
