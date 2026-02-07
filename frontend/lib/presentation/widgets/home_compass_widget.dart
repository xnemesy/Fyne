
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/home_state_provider.dart';
import '../../providers/budget_provider.dart';

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
        
        const SizedBox(height: 32), // Reduced from 48

        // BLOCK 2: COMPASS
        _buildCompassBlock(dailyAllowance),

        const SizedBox(height: 32), // Reduced from 48

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
          const SizedBox(height: 12), // Reduced from 16
          Text(
            homeState.title,
            style: GoogleFonts.lora(
              fontSize: 28, // Reduced from 32
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4), // Reduced from 8
          Text(
            homeState.subtitle,
            style: GoogleFonts.inter(
              fontSize: 14, // Reduced from 15
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassBlock(double allowance) {
    // Color logic based on allowance status
    Color allowanceColor = const Color(0xFF4A6741); // Default Green
    if (allowance <= 0) {
      allowanceColor = const Color(0xFFA0665F); // Terra Cotta for Critical
    } else if (allowance < 10) {
      allowanceColor = const Color(0xFFB8884D); // Amber for Attention
    }

    return Column(
      children: [
        Text(
          "${allowance.toStringAsFixed(2)} €",
          style: GoogleFonts.lora(
            fontSize: 44, // Matched to spec
            fontWeight: FontWeight.w300, 
            color: allowanceColor,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4), 
        Text(
          allowance <= 0 ? "limite raggiunto oggi" : "spazio disponibile oggi",
          style: GoogleFonts.inter(
            fontSize: 11, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: allowanceColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 20), 
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F2), // Matched to spec
            borderRadius: BorderRadius.circular(2), // Matched to spec (radius 2px)
          ),
          child: Column(
            children: [
              Text(
                "Margine giornaliero medio",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: const Color(0xFF1A1A1A).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "per il resto del mese",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A).withOpacity(0.6),
                ),
              ),
            ],
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
          Icon(LucideIcons.info, size: 12, color: const Color(0xFF1A1A1A).withOpacity(0.2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              homeState.contextLine,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11, // Reduced from 12
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
