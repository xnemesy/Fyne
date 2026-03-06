import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/fyne_theme.dart';
import '../../../providers/insights_provider.dart';
import '../fyne_shimmer.dart';

/// Grafico a linee che mostra l'andamento del patrimonio netto nel tempo.
/// Legge `insightsProvider.netWorthHistory` (List<FlSpot> già calcolati).
/// Gestisce: caricamento (Shimmer), dati assenti, dati disponibili.
class BalanceChart extends ConsumerWidget {
  const BalanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          const SizedBox(height: 20),
          _buildChartBody(context, state),
        ],
      ),
    );
  }

  /// Intestazione: titolo sezione + etichetta periodo selezionato
  Widget _buildHeader(BuildContext context, InsightsState state) {
    final periodoLabel = switch (state.selectedPeriod) {
      InsightsPeriod.day  => 'Oggi',
      InsightsPeriod.week => 'Settimana',
      InsightsPeriod.month => 'Mese',
      InsightsPeriod.year => 'Anno',
    };

    return Row(
      children: [
        Text(
          'Andamento Patrimonio',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: FyneColors.forest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            periodoLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FyneColors.forest,
            ),
          ),
        ),
      ],
    );
  }

  /// Corpo: Shimmer | vuoto | grafico
  Widget _buildChartBody(BuildContext context, InsightsState state) {
    if (state.isLoading) {
      return FyneShimmer(
        width: double.infinity,
        height: 160,
        borderRadius: BorderRadius.circular(12),
      );
    }

    if (state.netWorthHistory.isEmpty) {
      return _buildEmpty(context);
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: _buildLineChart(context, state.netWorthHistory),
        ),
        const SizedBox(height: 12),
        _buildFooter(context, state),
      ],
    );
  }

  /// Placeholder quando non ci sono ancora transazioni registrate
  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.lineChart,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),
            Text(
              'Nessun dato disponibile',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grafico a linee con pattern identico a NetWorthChart ma adattato alla Dashboard
  Widget _buildLineChart(BuildContext context, List<FlSpot> spots) {
    return LineChart(
      LineChartData(
        // Niente griglia — design minimalista
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // Nessun titolo sugli assi — il grafico parla da solo
        titlesData: const FlTitlesData(
          leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        // Tooltip al tocco: mostra valore € formattato
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) =>
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88),
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  NumberFormat.currency(
                    locale: 'it_IT',
                    symbol: '€',
                    decimalDigits: 0,
                  ).format(spot.y),
                  GoogleFonts.lora(
                    color: FyneColors.paper,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: FyneColors.forest,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            // Riempimento gradiente sotto la curva: effetto premium
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FyneColors.forest.withValues(alpha: 0.18),
                  FyneColors.forest.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Riga inferiore: variazione netta del periodo
  Widget _buildFooter(BuildContext context, InsightsState state) {
    final delta = state.income - state.expenses;
    final isPositivo = delta >= 0;
    final colore = isPositivo ? FyneColors.forest : FyneColors.rust;

    return Row(
      children: [
        Icon(
          isPositivo ? LucideIcons.trendingUp : LucideIcons.trendingDown,
          color: colore,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          '${isPositivo ? '+' : ''}${NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2).format(delta)} nel periodo',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colore,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
