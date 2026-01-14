import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/budget.dart'; // We'll need a transaction model too

class AnalyticsData {
  final Map<String, double> categoryDistribution;
  final List<double> weeklyNetWorth;
  final double burnRate;

  AnalyticsData({
    required this.categoryDistribution,
    required this.weeklyNetWorth,
    required this.burnRate,
  });
}

class FinancialAnalyticsService {
  /**
   * Performs heavy data aggregation using compute (Isolate) to avoid UI jank.
   * Useful when processing > 1000 transactions.
   */
  Future<AnalyticsData> calculateInsights(List<dynamic> transactions, List<Account> accounts) async {
    return await compute(_processData, {
      'transactions': transactions,
      'accounts': accounts,
    });
  }

  static AnalyticsData _processData(Map<String, dynamic> data) {
    final transactions = data['transactions'] as List<dynamic>;
    final accounts = data['accounts'] as List<Account>;

    Map<String, double> catDist = {};
    List<double> netWorthHistory = List.filled(7, 0.0);
    
    // 1. Category Distribution
    for (var tx in transactions) {
      final catId = tx['category_uuid'] ?? 'unknown';
      final amount = (tx['amount'] as num).toDouble();
      catDist[catId] = (catDist[catId] ?? 0.0) + amount;
    }

    // 2. Weekly Net Worth (Simplified Mock Logic for demo)
    // In a real app, this would iterate back 7 days and sum balances
    double currentTotal = 0.0;
    for (var acc in accounts) {
      currentTotal += double.tryParse(acc.decryptedBalance ?? '0') ?? 0.0;
    }
    
    for (int i = 0; i < 7; i++) {
       netWorthHistory[i] = currentTotal - (i * 150); // Simulating an upward trend
    }

    // 3. Burn Rate Calculation
    // Avg spending per day in the last 30 days
    final totalSpent30Days = catDist.values.fold(0.0, (sum, val) => sum + val);
    final burnRate = totalSpent30Days / 30;

    return AnalyticsData(
      categoryDistribution: catDist,
      weeklyNetWorth: netWorthHistory.reversed.toList(),
      burnRate: burnRate,
    );
  }
}
