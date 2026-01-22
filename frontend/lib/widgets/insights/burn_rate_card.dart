
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("RITMO DI SPESA", style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.3))),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("${dailyBurn.toStringAsFixed(2)} €", style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const Spacer(),
              Icon(
                trend <= 0 ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                color: trend <= 0 ? const Color(0xFF4A6741) : const Color(0xFFD63031),
                size: 20
              ),
              const SizedBox(width: 4),
              Text(
                "${trend.abs().toStringAsFixed(0)}%", 
                style: GoogleFonts.inter(
                  color: trend <= 0 ? const Color(0xFF4A6741) : const Color(0xFFD63031), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14
                )
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("/ giorno (ultimi 30gg)", style: GoogleFonts.inter(color: const Color(0xFF1A1A1A).withOpacity(0.3), fontSize: 12)),
        ],
      ),
    );
  }
}
