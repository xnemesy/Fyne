
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/account.dart';
import '../domain/models/transaction.dart';
import '../models/budget.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

class InsightsState {
  final double netWorth;
  final List<FlSpot> netWorthHistory;
  final double burnRate; // Daily burn rate (last 30 days)
  final double burnRateTrend; // Percentage change vs specific baseline (e.g. -5%)
  final double income;
  final double expenses;
  final double savings;
  final double savingsRate;
  final List<BudgetStatus> topCategories;
  final bool isLoading;

  InsightsState({
    this.netWorth = 0,
    this.netWorthHistory = const [],
    this.burnRate = 0,
    this.burnRateTrend = 0,
    this.income = 0,
    this.expenses = 0,
    this.savings = 0,
    this.savingsRate = 0,
    this.topCategories = const [],
    this.isLoading = true,
  });

  InsightsState copyWith({
    double? netWorth,
    List<FlSpot>? netWorthHistory,
    double? burnRate,
    double? burnRateTrend,
    double? income,
    double? expenses,
    double? savings,
    double? savingsRate,
    List<BudgetStatus>? topCategories,
    bool? isLoading,
  }) {
    return InsightsState(
      netWorth: netWorth ?? this.netWorth,
      netWorthHistory: netWorthHistory ?? this.netWorthHistory,
      burnRate: burnRate ?? this.burnRate,
      burnRateTrend: burnRateTrend ?? this.burnRateTrend,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      savings: savings ?? this.savings,
      savingsRate: savingsRate ?? this.savingsRate,
      topCategories: topCategories ?? this.topCategories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class InsightsNotifier extends StateNotifier<InsightsState> {
  final Ref ref;

  InsightsNotifier(this.ref) : super(InsightsState()) {
    _init();
  }

  void _init() {
    // Listen to changes in dependencies and re-calculate
    ref.listen<AsyncValue<List<Account>>>(accountsProvider, (_, next) => _recalculate());
    ref.listen<AsyncValue<List<TransactionModel>>>(transactionsProvider, (_, next) => _recalculate());
    ref.listen<List<BudgetStatus>>(budgetSummaryProvider, (_, next) => _recalculate());
    
    // Initial calculation
    _recalculate();
  }

  void _recalculate() {
    final accountsState = ref.read(accountsProvider);
    final transactionsState = ref.read(transactionsProvider);
    final budgetSummaries = ref.read(budgetSummaryProvider);

    if (accountsState.isLoading || transactionsState.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final accounts = accountsState.value ?? [];
    final transactions = transactionsState.value ?? [];

    // 1. Calculate Net Worth
    double currentNetWorth = 0;
    for (var acc in accounts) {
      final balStr = acc.decryptedBalance?.replaceAll(',', '.') ?? '0';
      currentNetWorth += double.tryParse(balStr) ?? 0;
    }

    // 2. Calculate Net Worth History (Dynamic Spots)
    final historySpots = _generateDynamicSpots(currentNetWorth, transactions);

    // 3. Calculate Burn Rate
    double totalSpent30Days = 0;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    for (var tx in transactions) {
      // Assuming negative amount is expense
      if (tx.amount < 0 && tx.bookingDate.isAfter(thirtyDaysAgo)) {
        totalSpent30Days += tx.amount.abs();
      }
    }
    final dailyBurn = transactions.isEmpty ? 0.0 : totalSpent30Days / 30;
    // Note: Trend calculation would require previous period data not currently available strictly in this logic, 
    // keeping constant -5% placeholder logic or implementing real comparison later. 
    // For now we keep the placeholder logic from original code or 0 if not implementing full history.
    
    // 4. Calculate Cash Flow (Current Month)
    double income = 0;
    double expenses = 0;
    
    for (var tx in transactions) {
      if (tx.bookingDate.month == now.month && tx.bookingDate.year == now.year) {
        if (tx.amount > 0) {
          income += tx.amount;
        } else {
          expenses += tx.amount.abs();
        }
      }
    }
    final savings = income - expenses;
    final savingsRate = income > 0 ? (savings / income) : 0.0;

    // 5. Top Categories
    final sortedSummaries = List<BudgetStatus>.from(budgetSummaries)..sort((a, b) => b.spent.compareTo(a.spent));

    state = state.copyWith(
      netWorth: currentNetWorth,
      netWorthHistory: historySpots,
      burnRate: dailyBurn,
      burnRateTrend: -5.0, // Placeholder as per original
      income: income,
      expenses: expenses,
      savings: savings,
      savingsRate: savingsRate,
      topCategories: sortedSummaries,
      isLoading: false,
    );
  }

  List<FlSpot> _generateDynamicSpots(double current, List<TransactionModel> transactions) {
    // We want 7 spots, from 6 days ago (x=0) to today (x=6)
    final List<FlSpot> spots = [];
    double balanceAtTime = current;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Most recent spot is today
    spots.add(FlSpot(6, balanceAtTime));
    
    // Reverse historical days
    for (int i = 1; i <= 6; i++) {
        final dayToReverse = today.subtract(Duration(days: i - 1));
        final nextDay = dayToReverse.add(const Duration(days: 1));
        
        final dayTxs = transactions.where((tx) => 
            tx.bookingDate.isAfter(dayToReverse) && tx.bookingDate.isBefore(nextDay));
        
        for (var tx in dayTxs) {
            // If tx amount was -10 (expense), balance BEFORE this tx was current + 10
            // So executing the transaction (current - 10) gave us current.
            // Reversing means: balanceAtTime = balanceAtTime - tx.amount
            // Example: Today balance 100. Yesterday spent 20 (tx = -20).
            // Balance yesterday end = 100. Balance yesterday start (or day before end) = 100 - (-20) = 120.
            // Wait, logic in original code: balanceAtTime -= tx.amount.
            // If tx is -20, balanceAtTime -= -20 => balanceAtTime += 20. Correct.
            balanceAtTime -= tx.amount;
        }
        spots.add(FlSpot((6 - i).toDouble(), balanceAtTime));
    }

    return spots.reversed.toList();
  }
}

final insightsProvider = StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier(ref);
});

