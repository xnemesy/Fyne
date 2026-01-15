import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import 'package:intl/intl.dart';

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
        color: const Color(0xFFFBFBF9), // Paper White
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF4A6741).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6741).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DISPONIBILITÀ GIORNALIERA",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFF4A6741).withOpacity(0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6741).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Ottimale",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A6741),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencyFormat.format(allowance).split(',')[0],
                style: GoogleFonts.lora(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A6741),
                ),
              ),
              Text(
                ",${currencyFormat.format(allowance).split(',')[1]}",
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A6741).withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6741).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (allowance / (totalBudget / 30)).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6741),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Spendi con consapevolezza oggi per mantenere il tuo equilibrio finanziario.",
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
