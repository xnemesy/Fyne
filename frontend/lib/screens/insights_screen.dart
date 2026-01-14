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
    final accountsAsync = ref.watch(accountsProvider);

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
              background: _buildNetWorthChart(),
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
                  _buildTopCategoriesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyanAccent.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 10000),
                FlSpot(1, 10200),
                FlSpot(2, 10100),
                FlSpot(3, 10500),
                FlSpot(4, 10800),
                FlSpot(5, 11000),
                FlSpot(6, 11500),
              ],
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
    );
  }

  Widget _buildToggleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Spese per Categoria",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        _buildGlassToggle(),
      ],
    );
  }

  Widget _buildGlassToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _toggleBtn("Corrente", !_showPreviousWeek),
          _toggleBtn("Precedente", _showPreviousWeek),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showPreviousWeek = !active ? !_showPreviousWeek : _showPreviousWeek),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.cyanAccent : Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBurnRateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Burn Rate Giornaliero", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text("42.50 €", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20),
              const Text("-5%", style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Basato sulla media delle ultime 2 settimane", style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection() {
    return Column(
      children: [
        _categoryRow("Shopping", "450 €", 0.6, Colors.orangeAccent),
        _categoryRow("Cibo", "280 €", 0.4, Colors.redAccent),
        _categoryRow("Trasporti", "120 €", 0.2, Colors.blueAccent),
      ],
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
