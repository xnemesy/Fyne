import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../providers/account_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _showPreviousWeek = false;

  @override
  Widget build(BuildContext context) {
    // In production, we'd watch an InsightsProvider that uses the AnalyticsService
    // For now, we connect to existing providers
    final accountsAsync = ref.watch(accountsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            flexibleSpace: FlexibleSpaceBar(
              background: accountsAsync.when(
                data: (accounts) => _buildNetWorthChart(accounts),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Icon(Icons.error, color: Colors.white24)),
              ),
            ),
            title: Text("Financial Insights", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildToggleHeader(),
                  const SizedBox(height: 25),
                  _buildBurnRateSection(),
                  const SizedBox(height: 30),
                  budgetsAsync.when(
                    data: (budgets) => _buildTopCategoriesSection(budgets),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text("Impossibile caricare categorie"),
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
    // Calculate total net worth dynamically
    double netWorth = 0;
    for (var acc in accounts) {
      netWorth += double.tryParse(acc.decryptedBalance ?? '0') ?? 0;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyanAccent.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(
            "${netWorth.toStringAsFixed(2)} €",
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateDynamicSpots(netWorth), // Dynamic based on real data
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowArea: BarAreaData(
                      show: true,
                      color: Colors.cyanAccent.withOpacity(0.1),
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
    // In production this would come from a history table. 
    // Mocking the trend slightly but using the REAL current value as endpoint.
    return [
      FlSpot(0, current * 0.95),
      FlSpot(1, current * 0.96),
      FlSpot(2, current * 0.94),
      FlSpot(3, current * 0.97),
      FlSpot(4, current * 0.98),
      FlSpot(5, current * 0.99),
      FlSpot(6, current),
    ];
  }

  Widget _buildTopCategoriesSection(List<Budget> budgets) {
    // Sort budgets by usage to show 'Top Categories'
    final sortedBudgets = List<Budget>.from(budgets)
      ..sort((a, b) => b.currentSpent.compareTo(a.currentSpent));

    return Column(
      children: sortedBudgets.take(5).map((budget) {
        return _categoryRow(
          budget.decryptedCategoryName ?? "Sconosciuta",
          "${budget.currentSpent.toStringAsFixed(0)} €",
          budget.progress,
          budget.isOverBudget ? Colors.redAccent : Colors.cyanAccent,
        );
      }).toList(),
    );
  }

  Widget _categoryRow(String label, String amount, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(amount, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: color,
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
