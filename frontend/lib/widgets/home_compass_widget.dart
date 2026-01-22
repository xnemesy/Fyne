
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/home_state_provider.dart';
import '../providers/budget_provider.dart';

class HomeCompassWidget extends ConsumerWidget {
  const HomeCompassWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeStateProvider);
    final dailyAllowance = ref.watch(dailyAllowanceProvider);

    return Column(
      children: [
        // BLOCK 1: STATE
        _buildStateBlock(homeState),
        
        const SizedBox(height: 48),

        // BLOCK 2: COMPASS
        _buildCompassBlock(dailyAllowance),

        const SizedBox(height: 48),

        // BLOCK 3: CONTEXT
        _buildContextBlock(homeState),
      ],
    );
  }

  Widget _buildStateBlock(HomeState homeState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "STATO ATTUALE",
            style: GoogleFonts.inter(
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            homeState.title,
            style: GoogleFonts.lora(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            homeState.subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassBlock(double allowance) {
    return Column(
      children: [
        Text(
          "${allowance.toStringAsFixed(2)} €",
          style: GoogleFonts.lora(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A6741),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "spazio medio al giorno",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Usato solo come riferimento, non come limite.",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A).withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextBlock(HomeState homeState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.info, size: 14, color: const Color(0xFF1A1A1A).withOpacity(0.2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              homeState.contextLine,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1A1A1A).withOpacity(0.3),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
