import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';

class CompactCashFlowChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  
  const CompactCashFlowChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;

    // Calculate daily accumulated expenses
    Map<int, double> dailyExpenses = {};
    for (int i = 1; i <= totalDays; i++) {
      dailyExpenses[i] = 0;
    }

    for (var tx in transactions) {
      if (tx.bookingDate.month == now.month && tx.bookingDate.year == now.year && tx.amount < 0) {
        dailyExpenses[tx.bookingDate.day] = (dailyExpenses[tx.bookingDate.day] ?? 0) + tx.amount.abs();
      }
    }

    List<FlSpot> spots = [];
    double accumulated = 0;
    for (int i = 1; i <= currentDay; i++) {
      accumulated += dailyExpenses[i]!;
      spots.add(FlSpot(i.toDouble(), accumulated));
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "ANDAMENTO SPESE MENSILE",
              style: GoogleFonts.inter(
                letterSpacing: 1.5,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A).withOpacity(0.3),
              ),
            ),
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
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF4A6741),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF4A6741).withOpacity(0.15),
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
}
