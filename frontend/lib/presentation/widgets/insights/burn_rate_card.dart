
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/fyne_theme.dart';

class BurnRateCard extends StatelessWidget {
  final double dailyBurn;
  final double trend;

  const BurnRateCard({
    super.key,
    required this.dailyBurn,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: FyneColors.ink.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("RITMO DI SPESA MEDIO", style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("${dailyBurn.toStringAsFixed(2)} €", style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Icon(
                trend <= 0 ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                color: trend <= 0 ? FyneColors.forest : colorScheme.error,
                size: 20
              ),
              const SizedBox(width: 4),
              Text(
                "${trend.abs().toStringAsFixed(0)}%",
                style: GoogleFonts.inter(
                  color: trend <= 0 ? FyneColors.forest : colorScheme.error,
                  fontWeight: FontWeight.bold, 
                  fontSize: 14
                )
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("/ giorno (ultimi 30gg)", style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12)),
        ],
      ),
    );
  }
}
