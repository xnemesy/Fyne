
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/budget_provider.dart';

class DailyAllowanceCard extends ConsumerWidget {
  const DailyAllowanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This provider calculates remaining budget / days remaining
    final dailyAllowance = ref.watch(dailyAllowanceProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6741), // Primary Green
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6741).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.calendarCheck, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                "BUDGET GIORNALIERO",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            dailyAllowance <= 0 ? "Limite raggiunto" : "${dailyAllowance.toStringAsFixed(2)} €",
            style: GoogleFonts.lora(
              fontSize: dailyAllowance <= 0 ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          if (dailyAllowance <= 0) ...[
            const SizedBox(height: 4),
            Text(
              "Spazio disponibile oggi: 0 €",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            "Puoi spendere questo importo ogni giorno per il resto del mese senza sforare il budget totale.",
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
