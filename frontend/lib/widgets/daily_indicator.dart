import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/daily_budget_provider.dart';

class DailyIndicator extends ConsumerWidget {
  const DailyIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(dailyBudgetProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  letterSpacing: 2,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A).withOpacity(0.3),
                ),
              ),
              if (info.isExhausted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD63031).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "BUDGET ESAURITO",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD63031),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${info.dailyAllowance.toStringAsFixed(2)} €",
                style: GoogleFonts.lora(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: info.isExhausted ? const Color(0xFFD63031) : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "/ oggi",
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1A1A).withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: info.isExhausted ? 1.0 : (info.dailyAllowance / (info.dailyAverageNeeded * 1.5)).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF2F2F0),
              color: info.isExhausted ? const Color(0xFFD63031) : const Color(0xFF4A6741),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            info.isExhausted 
              ? "Hai sforato il budget mensile. Risparmia per i prossimi ${info.daysRemaining} giorni."
              : "Puoi spendere questo importo oggi per restare in target.",
            style: GoogleFonts.inter(
              color: const Color(0xFF1A1A1A).withOpacity(0.4),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
