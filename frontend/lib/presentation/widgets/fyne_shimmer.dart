import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/fyne_theme.dart';

class FyneShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const FyneShimmer({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? FyneColors.paper.withValues(alpha: 0.1) : FyneColors.ink.withValues(alpha: 0.05),
      highlightColor: isDark ? FyneColors.paper.withValues(alpha: 0.24) : FyneColors.ink.withValues(alpha: 0.02),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: FyneColors.paper,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class FyneTransactionShimmer extends StatelessWidget {
  const FyneTransactionShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const FyneShimmer(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FyneShimmer(width: MediaQuery.of(context).size.width * 0.4, height: 16),
                const SizedBox(height: 8),
                FyneShimmer(width: MediaQuery.of(context).size.width * 0.2, height: 12),
              ],
            ),
          ),
          const FyneShimmer(width: 60, height: 20),
        ],
      ),
    );
  }
}

/// Placeholder shimmer per una riga account nel WalletScreen.
/// Morfologicamente identico a `_buildAccountRow` in wallet_screen.dart:
/// icona circolare 40×40 | nome + tipo conto | importo a destra.
class FyneAccountShimmer extends StatelessWidget {
  const FyneAccountShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const FyneShimmer(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FyneShimmer(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: 14,
                ),
                const SizedBox(height: 6),
                FyneShimmer(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: 12,
                ),
              ],
            ),
          ),
          const FyneShimmer(width: 64, height: 16),
        ],
      ),
    );
  }
}

/// Placeholder shimmer per una riga budget in BudgetsScreen.
/// Struttura: nome categoria + importo | barra progress | quota spesa.
class FyneBudgetShimmer extends StatelessWidget {
  const FyneBudgetShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FyneShimmer(width: width * 0.30, height: 16),
                    FyneShimmer(width: width * 0.20, height: 16),
                  ],
                ),
                const SizedBox(height: 12),
                FyneShimmer(
                  width: double.infinity,
                  height: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                FyneShimmer(width: width * 0.25, height: 12),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

/// Placeholder shimmer per una riga spesa programmata in ScheduledScreen.
/// Morfologicamente identico a `_buildScheduledItem`: icona | testo | importo.
class FyneScheduledShimmer extends StatelessWidget {
  const FyneScheduledShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const FyneShimmer(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FyneShimmer(width: width * 0.35, height: 14),
                      const SizedBox(height: 6),
                      FyneShimmer(width: width * 0.25, height: 12),
                    ],
                  ),
                ),
                const FyneShimmer(width: 56, height: 18),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

/// Placeholder shimmer per la sezione Rapporti in InsightsScreen.
/// Struttura:
///   - Rettangolo alto 180px → placeholder grafico NetWorth
///   - Linea larga → placeholder numero patrimonio (testo grande)
///   - 3 pillole orizzontali → placeholder categorie
class FyneInsightsShimmer extends StatelessWidget {
  const FyneInsightsShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FyneShimmer(width: width * 0.55, height: 40),
          const SizedBox(height: 8),
          FyneShimmer(width: width * 0.25, height: 14),
          const SizedBox(height: 28),
          FyneShimmer(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FyneShimmer(width: width * 0.22, height: 32, borderRadius: BorderRadius.circular(16)),
              const SizedBox(width: 8),
              FyneShimmer(width: width * 0.22, height: 32, borderRadius: BorderRadius.circular(16)),
              const SizedBox(width: 8),
              FyneShimmer(width: width * 0.22, height: 32, borderRadius: BorderRadius.circular(16)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
