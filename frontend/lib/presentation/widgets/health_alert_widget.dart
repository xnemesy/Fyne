import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/transaction_provider.dart';

class HealthAlertWidget extends ConsumerWidget {
  const HealthAlertWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    
    return transactionsAsync.when(
      data: (transactions) {
        // Find if there are critical transactions today
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final criticalTx = transactions.where((tx) => 
          tx.bookingDate.isAtSameMomentAs(today) || tx.bookingDate.isAfter(today)).where((tx) => 
            tx.categoryName == 'Fast Food' || tx.categoryName == 'Vizi'
        ).toList();

        if (criticalTx.isEmpty) return const SizedBox.shrink();

        final tx = criticalTx.first;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FyneColors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FyneColors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.flame, color: FyneColors.amber, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Consapevolezza Benessere",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FyneColors.amber,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hai registrato una spesa in ${tx.categoryName}. Ricorda il tuo obiettivo salute (BMI: 29.1). Ti senti ancora in linea con il tuo piano?",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

