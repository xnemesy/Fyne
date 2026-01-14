import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../providers/account_provider.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../models/account.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _showPreviousWeek = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFFBFBF9),
            iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
            flexibleSpace: FlexibleSpaceBar(
              background: accountsAsync.when(
                data: (accounts) => _buildNetWorthChart(accounts),
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                error: (_, __) => const Center(child: Icon(LucideIcons.alertTriangle, color: Color(0xFF1A1A1A))),
              ),
            ),
            title: Text("Resoconto", style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildToggleHeader(),
                  const SizedBox(height: 32),
                  _buildBurnRateSection(),
                  const SizedBox(height: 40),
                  Text("DISTRIBUZIONE SPESE", style: GoogleFonts.inter(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.4))),
                  const SizedBox(height: 20),
                  budgetsAsync.when(
                    data: (budgets) => _buildTopCategoriesSection(budgets),
                    loading: () => const LinearProgressIndicator(color: Color(0xFF4A6741), backgroundColor: Color(0xFFF2F2F0)),
                    error: (_, __) => const Text("Impossibile caricare i dati"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthChart(List<Account> accounts) {
    double netWorth = 0;
    for (var acc in accounts) {
      netWorth += double.tryParse(acc.decryptedBalance ?? '0') ?? 0;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
      child: Column(
        children: [
          Text(
            "${netWorth.toStringAsFixed(2)} €",
            style: GoogleFonts.lora(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
          ),
          Text(
            "PATRIMONIO NETTO",
            style: GoogleFonts.inter(letterSpacing: 3, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.3)),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF1A1A1A),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${spot.y.toStringAsFixed(0)} €",
                          GoogleFonts.lora(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateDynamicSpots(netWorth),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF4A6741),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF4A6741).withOpacity(0.1),
                          const Color(0xFF4A6741).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateDynamicSpots(double current) {
    return [
      FlSpot(0, current * 0.95), FlSpot(1, current * 0.96),
      FlSpot(2, current * 0.94), FlSpot(3, current * 0.97),
      FlSpot(4, current * 0.98), FlSpot(5, current * 0.99),
      FlSpot(6, current),
    ];
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

  Widget _buildBurnRateSection() {
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
          Text("VELOCITÀ DI SPESA", style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.3))),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("42.50 €", style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const Spacer(),
              const Icon(LucideIcons.trendingDown, color: Color(0xFF4A6741), size: 20),
              const SizedBox(width: 4),
              Text("-5%", style: GoogleFonts.inter(color: const Color(0xFF4A6741), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text("/ giorno", style: GoogleFonts.inter(color: const Color(0xFF1A1A1A).withOpacity(0.3), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection(List<Budget> budgets) {
    final sortedBudgets = List<Budget>.from(budgets)..sort((a, b) => b.currentSpent.compareTo(a.currentSpent));
    return Column(
      children: sortedBudgets.take(5).map((budget) {
        return _categoryRow(
          budget.decryptedCategoryName ?? "Sconosciuta",
          "${budget.currentSpent.toStringAsFixed(0)} €",
          budget.progress,
          budget.isOverBudget ? const Color(0xFFD63031) : const Color(0xFF4A6741),
        );
      }).toList(),
    );
  }

  Widget _categoryRow(String label, String amount, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              Text(amount, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF2F2F0),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
