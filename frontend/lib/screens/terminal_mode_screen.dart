import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../widgets/decrypted_value.dart';
import '../providers/wallet_provider.dart';

class TerminalModeScreen extends ConsumerStatefulWidget {
  final List<Account> accounts;
  const TerminalModeScreen({super.key, required this.accounts});

  @override
  ConsumerState<TerminalModeScreen> createState() => _TerminalModeScreenState();
}

class _TerminalModeScreenState extends ConsumerState<TerminalModeScreen> {
  String _timeframe = '1Y';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(walletSummaryProvider);
    final totalNetWorth = summary.netWorth;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PATRIMONIO NETTO",
                          style: GoogleFonts.inter(
                            letterSpacing: 4,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A).withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DecryptedValue(
                          value: totalNetWorth.toStringAsFixed(2),
                          isLarge: true,
                          style: GoogleFonts.lora(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    _buildTimeframeSelector(),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFF1A1A1A).withOpacity(0.03),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU', 'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'];
                              if (value % 1 != 0 || value < 0 || value >= 12) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  months[value.toInt()],
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1A1A).withOpacity(0.2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateHistoricalSpots(totalNetWorth),
                          isCurved: true,
                          color: const Color(0xFF4A6741),
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF4A6741).withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 40,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['1M', '3M', '6M', '1Y'].map((t) => _timeframeBtn(t)).toList(),
      ),
    );
  }

  Widget _timeframeBtn(String t) {
    final active = _timeframe == t;
    return GestureDetector(
      onTap: () => setState(() => _timeframe = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          t,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A).withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateHistoricalSpots(double current) {
    // Mocking historical data based on current net worth
    // Ideally this should come from historical snapshots if available
    return [
      FlSpot(0, current * 0.8),
      FlSpot(1, current * 0.82),
      FlSpot(2, current * 0.81),
      FlSpot(3, current * 0.85),
      FlSpot(4, current * 0.88),
      FlSpot(5, current * 0.9),
      FlSpot(6, current * 0.89),
      FlSpot(7, current * 0.92),
      FlSpot(8, current * 0.95),
      FlSpot(9, current * 0.94),
      FlSpot(10, current * 0.98),
      FlSpot(11, current),
    ];
  }
}
