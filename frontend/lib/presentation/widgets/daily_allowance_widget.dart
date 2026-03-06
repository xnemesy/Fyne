import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/budget_provider.dart';

class DailyAllowanceWidget extends ConsumerWidget {
  const DailyAllowanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowance = ref.watch(dailyAllowanceProvider);
    final totalBudget = ref.watch(totalMonthlyBudgetProvider);
    
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: FyneColors.forest.withValues(alpha:0.1)),
        boxShadow: [
          BoxShadow(
            color: FyneColors.forest.withValues(alpha:0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DISPONIBILITÀ GIORNALIERA",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.4),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencyFormat.format(allowance).split(',')[0],
                  style: GoogleFonts.lora(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  ",${currencyFormat.format(allowance).split(',')[1]}",
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (allowance > 0 ? FyneColors.forest : FyneColors.danger).withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                allowance > 0 ? "RITMO SOSTENIBILE" : "BUDGET SUPERATO",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: allowance > 0 ? FyneColors.forest : FyneColors.danger,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: totalBudget > 0 ? (allowance / (totalBudget / 30)).clamp(0.0, 1.0) : 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: FyneColors.forest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Calcolato su ${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1} giorni rimanenti",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                allowance > 0 ? "In equilibrio" : "Revisione necessaria",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
