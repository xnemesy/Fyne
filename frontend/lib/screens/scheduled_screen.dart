import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScheduledTransactionsScreen extends StatelessWidget {
  const ScheduledTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(LucideIcons.calendar, size: 28, color: Color(0xFF007AFF)),
                        _headerAction(LucideIcons.plus, () {}, isPrimary: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Programmate",
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      "Pagamenti ricorrenti e spese future",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1A1A1A).withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.calendarClock, size: 64, color: const Color(0xFF1A1A1A).withOpacity(0.05)),
                    const SizedBox(height: 24),
                    Text(
                      "Nessun pagamento programmato",
                      style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Aggiungi affitti, abbonamenti o rate.",
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF007AFF) : const Color(0xFFE9E9EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF1A1A1A), size: 18),
      ),
    );
  }
}
