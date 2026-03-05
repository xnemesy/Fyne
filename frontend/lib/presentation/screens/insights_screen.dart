import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/animations/fyne_animations.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/haptics/fyne_haptics.dart';

import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/insights_provider.dart';

import '../widgets/fyne_shimmer.dart';
import '../../presentation/widgets/insights/net_worth_chart.dart';
import '../../presentation/widgets/insights/burn_rate_card.dart';
import '../../presentation/widgets/insights/cash_flow_card.dart';
import '../../presentation/widgets/insights/top_categories_list.dart';
import '../../presentation/widgets/insights/category_pie_chart.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final insightsState = ref.watch(insightsProvider);

    return Scaffold(
      // backgroundColor rimosso per supportare il dark mode
      body: RefreshIndicator(
        color: const Color(0xFF4A6741),
        onRefresh: () async {
          await FyneHaptics.onPullRefresh();
          await ref.read(accountsProvider.notifier).refresh();
          await ref.read(budgetsProvider.notifier).refresh();
          await ref.read(transactionsProvider.notifier).refresh();
          await FyneHaptics.light();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.pieChart,
                        size: 28, color: Color(0xFF34C759)),
                    const SizedBox(height: 20),
                    Text(
                      "Rapporti",
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Analisi dettagliata delle tue finanze",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FyneAnimations.slideUp(
                transitionKey:
                    'insights-body-${insightsState.selectedPeriod.name}-${insightsState.isLoading}',
                child: insightsState.isLoading
                    ? const FyneInsightsShimmer()
                    : (insightsState.netWorth == 0 &&
                            insightsState.income == 0 &&
                            insightsState.expenses == 0)
                        ? _buildEmptyState()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FyneAnimations.fadeScale(
                                      transitionKey: insightsState.netWorth
                                          .toStringAsFixed(2),
                                      child: Text(
                                        "${FyneCurrencyFormatter.format(insightsState.netWorth)} €",
                                        style: GoogleFonts.lora(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w300,
                                            color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                    ),
                                    Text(
                                      "patrimonio netto",
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface
                                              .withValues(alpha: 0.4)),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Container(
                                  height: 240,
                                  decoration: BoxDecoration(
                                    // Fix dark theme: usa surface del tema invece di Colors.white
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 10),
                                    ],
                                  ),
                                  child: NetWorthChart(
                                    netWorth: insightsState.netWorth,
                                    spots: insightsState.netWorthHistory,
                                  ),
                                ),
                              ),
                              if (insightsState.expenses > insightsState.income)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA0665F)
                                          .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      "Questo mese stai spendendo più di quanto guadagni. Il patrimonio si sta riducendo.",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: const Color(0xFFA0665F),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildToggleHeader(insightsState),
                                    const SizedBox(height: 32),
                                    BurnRateCard(
                                      dailyBurn: insightsState.burnRate,
                                      trend: insightsState.burnRateTrend,
                                    ),
                                    const SizedBox(height: 32),
                                    CashFlowCard(
                                      income: insightsState.income,
                                      expenses: insightsState.expenses,
                                      savings: insightsState.savings,
                                      savingsRate: insightsState.savingsRate,
                                    ),
                                    const SizedBox(height: 40),
                                    Text("DISTRIBUZIONE SPESE",
                                        style: GoogleFonts.inter(
                                            letterSpacing: 2,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface
                                                .withValues(alpha: 0.4))),
                                    const SizedBox(height: 20),
                                    // Grafico a torta: breakdown uscite per categoria
                                    CategoryPieChart(
                                      breakdown: insightsState.categoryBreakdown,
                                      totalExpenses: insightsState.expenses,
                                    ),
                                    const SizedBox(height: 32),
                                    if (insightsState.topCategories.isNotEmpty) ...
                                      [
                                        Text("PER BUDGET",
                                            style: GoogleFonts.inter(
                                                letterSpacing: 2,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface
                                                    .withValues(alpha: 0.4))),
                                        const SizedBox(height: 20),
                                        TopCategoriesList(
                                            categories: insightsState.topCategories),
                                      ],
                                  ],
                                ),
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

  Widget _buildEmptyState() {
    return Padding(
      key: const ValueKey('insights-empty'),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.barChart3,
                size: 40, color: Color(0xFF34C759)),
          ),
          const SizedBox(height: 24),
          Text(
            "Il tuo patrimonio apparirà qui",
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            "Non appena aggiungerai conti e movimenti, Fyne inizierà ad analizzare i tuoi dati per fornirti insight dettagliati.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildToggleHeader(InsightsState insightsState) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 160, // Ensure title has space but doesn't push too far
          child: Text(
            "Analisi ${_periodLabel(insightsState.selectedPeriod)}",
            style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        _buildPeriodToggle(insightsState.selectedPeriod),
      ],
    );
  }

  Widget _buildPeriodToggle(InsightsPeriod selectedPeriod) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleBtn("Day", selectedPeriod == InsightsPeriod.day,
              () => _setPeriod(InsightsPeriod.day)),
          _toggleBtn("Week", selectedPeriod == InsightsPeriod.week,
              () => _setPeriod(InsightsPeriod.week)),
          _toggleBtn("Month", selectedPeriod == InsightsPeriod.month,
              () => _setPeriod(InsightsPeriod.month)),
          _toggleBtn("Year", selectedPeriod == InsightsPeriod.year,
              () => _setPeriod(InsightsPeriod.year)),
        ],
      ),
    );
  }

  void _setPeriod(InsightsPeriod period) {
    FyneHaptics.onPeriodChange();
    ref.read(insightsProvider.notifier).setPeriod(period);
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _periodLabel(InsightsPeriod period) {
    switch (period) {
      case InsightsPeriod.day:
        return "Giornaliera";
      case InsightsPeriod.week:
        return "Settimanale";
      case InsightsPeriod.month:
        return "Mensile";
      case InsightsPeriod.year:
        return "Annuale";
    }
  }
}
