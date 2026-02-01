import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/models/transaction.dart';

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
      height: 220, // Increased height for labels
      padding: const EdgeInsets.fromLTRB(0, 20, 20, 10), // Added right padding
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
                color: Colors.black54, // Darker text
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45, // Increased space
                      getTitlesWidget: (value, meta) {
                         return Text(value.toInt().toString(), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "Questo andamento include anche spese future",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.black38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

