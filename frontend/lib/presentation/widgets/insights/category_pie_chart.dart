import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/fyne_theme.dart';
import '../../../providers/insights_provider.dart';

// ─── CategoryPieChart ─────────────────────────────────────────────────────────
//
// Grafico a torta delle uscite mensili per categoria.
// Utilizza fl_chart offline — nessuna libreria AI/ML/tracking.
// Dark-themed: sfondo trasparente, palette verde-varianti Fyne (#4A6741).

class CategoryPieChart extends StatefulWidget {
  final List<CategoryAmount> breakdown;
  final double totalExpenses;

  const CategoryPieChart({
    super.key,
    required this.breakdown,
    required this.totalExpenses,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.breakdown.isEmpty) {
      return _buildEmptyPlaceholder(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grafico a torta
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 52,
              sections: _buildSections(),
            ),
          ),
        ),

        // Testo centrale: totale spese
        _buildCenterLabel(context),
        const SizedBox(height: 24),

        // Legenda
        _buildLegend(context),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = widget.totalExpenses > 0 ? widget.totalExpenses : 1;

    return List.generate(widget.breakdown.length, (i) {
      final item        = widget.breakdown[i];
      final isTouched   = i == _touchedIndex;
      final percentage  = (item.amount / total * 100);
      final radius      = isTouched ? 70.0 : 58.0;

      return PieChartSectionData(
        color:      item.color,
        value:      item.amount,
        title:      isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius:     radius,
        titleStyle: GoogleFonts.inter(
          fontSize:   13,
          fontWeight: FontWeight.bold,
          color:      FyneColors.paper,
        ),
        badgeWidget:  !isTouched ? null : null,
      );
    });
  }

  Widget _buildCenterLabel(BuildContext context) {
    // Solo testo sopra il grafico (Stack non necessario — PieChart gestisce il centro)
    return Center(
      child: Text(
        '− ${_formatAmount(widget.totalExpenses)} €',
        style: GoogleFonts.lora(
          fontSize:   16,
          fontWeight: FontWeight.bold,
          color:      FyneColors.rust,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final onSurface  = Theme.of(context).colorScheme.onSurface;
    final items      = widget.breakdown.take(7).toList();

    return Wrap(
      spacing:    12,
      runSpacing: 10,
      children: items.map((item) {
        final pct = widget.totalExpenses > 0
            ? (item.amount / widget.totalExpenses * 100)
            : 0.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  10,
              height: 10,
              decoration: BoxDecoration(
                color:  item.color,
                shape:  BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${item.name} ${pct.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize:   11,
                color:      onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline,
              size: 40,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            'Nessuna uscita nel periodo',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
