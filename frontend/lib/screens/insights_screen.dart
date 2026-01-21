import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/insights_provider.dart';

import '../widgets/insights/net_worth_chart.dart';
import '../widgets/insights/burn_rate_card.dart';
import '../widgets/insights/cash_flow_card.dart';
import '../widgets/insights/top_categories_list.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _showPreviousWeek = false;

  @override
  Widget build(BuildContext context) {
    final insightsState = ref.watch(insightsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: RefreshIndicator(
        color: const Color(0xFF4A6741),
        onRefresh: () async {
           await ref.read(accountsProvider.notifier).refresh();
           await ref.read(budgetsProvider.notifier).refresh();
           ref.invalidate(transactionsProvider);
           // Insights provider calculates automatically when dependencies change
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
                    const Icon(LucideIcons.pieChart, size: 28, color: Color(0xFF34C759)),
                    const SizedBox(height: 20),
                    Text(
                      "Rapporti",
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      "Analisi dettagliata delle tue finanze",
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
            SliverToBoxAdapter(
              child: insightsState.isLoading 
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))))
                : (insightsState.netWorth == 0 && insightsState.income == 0 && insightsState.expenses == 0)
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Container(
                            height: 380,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
                              ],
                            ),
                            child: NetWorthChart(
                              netWorth: insightsState.netWorth,
                              spots: insightsState.netWorthHistory,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildToggleHeader(),
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
                              Text("DISTRIBUZIONE SPESE", style: GoogleFonts.inter(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.4))),
                              const SizedBox(height: 20),
                              TopCategoriesList(categories: insightsState.topCategories),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.barChart3, size: 40, color: Color(0xFF34C759)),
          ),
          const SizedBox(height: 24),
          Text(
            "Il tuo patrimonio apparirà qui",
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          Text(
            "Non appena aggiungerai conti e movimenti, Fyne inizierà ad analizzare i tuoi dati per fornirti insight dettagliati.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildToggleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Analisi Temporale",
          style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
        ),
        _buildMinimalToggle(),
      ],
    );
  }

  Widget _buildMinimalToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleBtn("Current", !_showPreviousWeek),
          _toggleBtn("Prev", _showPreviousWeek),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showPreviousWeek = !active ? !_showPreviousWeek : _showPreviousWeek),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A).withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
