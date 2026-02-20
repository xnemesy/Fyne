import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:fl_chart/fl_chart.dart';
import '../core/utils/date_utils.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

enum InsightsPeriod {
  day,
  week,
  month,
  year,
}

class InsightsState {
  final double netWorth;
  final List<FlSpot> netWorthHistory;
  final double burnRate; // Daily burn rate (last 30 days)
  final double
      burnRateTrend; // Percentage change vs specific baseline (e.g. -5%)
  final double income;
  final double expenses;
  final double savings;
  final double savingsRate;
  final List<BudgetStatus> topCategories;
  final bool isLoading;
  final InsightsPeriod selectedPeriod;

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
    this.selectedPeriod = InsightsPeriod.month,
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
    InsightsPeriod? selectedPeriod,
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
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
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
    ref.listen<AsyncValue<List<Account>>>(
        accountsProvider, (_, next) => _recalculate());
    ref.listen<AsyncValue<List<TransactionSummary>>>(
        transactionsProvider, (_, next) => _recalculate());
    ref.listen<List<BudgetStatus>>(
        budgetSummaryProvider, (_, next) => _recalculate());

    // Initial calculation
    _recalculate();
  }

  Future<void> _recalculate() async {
    final repo = ref.read(transactionRepositoryProvider);
    final accountsState = ref.read(accountsProvider);
    final transactionsState = ref.read(transactionsProvider);
    final budgetSummaries = ref.read(budgetSummaryProvider);

    if (accountsState.isLoading ||
        transactionsState.isLoading ||
        repo == null) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final accounts = accountsState.value ?? [];
    final transactions = transactionsState.value ?? [];
    final periodTransactions =
        _filterByPeriod(transactions, state.selectedPeriod);

    // 1. Calculate Net Worth
    double currentNetWorth = 0;
    for (var acc in accounts) {
      final balStr = acc.decryptedBalance?.replaceAll(',', '.') ?? '0';
      currentNetWorth += double.tryParse(balStr) ?? 0;
    }

    // 2. Calculate Net Worth History
    final historySpots = _generateDynamicSpots(currentNetWorth, transactions);

    // 3. Calculate Accurate Burn Rate (rolling 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final totalSpent30Days =
        await repo.getTotalSpentInRange(thirtyDaysAgo, now);
    final dailyBurn = totalSpent30Days / 30;

    // 4. Calculate Cash Flow
    double income = 0;
    double expenses = 0;
    for (var tx in periodTransactions) {
      if (tx.amount > 0)
        income += tx.amount;
      else
        expenses += tx.amount.abs();
    }
    final savings = income - expenses;
    final savingsRate = income > 0 ? (savings / income) : 0.0;

    // 5. Top Categories
    final sortedSummaries = List<BudgetStatus>.from(budgetSummaries)
      ..sort((a, b) => b.spent.compareTo(a.spent));

    state = state.copyWith(
      netWorth: currentNetWorth,
      netWorthHistory: historySpots,
      burnRate: dailyBurn,
      burnRateTrend: -5.0,
      income: income,
      expenses: expenses,
      savings: savings,
      savingsRate: savingsRate,
      topCategories: sortedSummaries,
      isLoading: false,
    );
  }

  void setPeriod(InsightsPeriod period) {
    if (state.selectedPeriod == period) return;
    state = state.copyWith(selectedPeriod: period, isLoading: true);
    _recalculate();
  }

  List<TransactionSummary> _filterByPeriod(
    List<TransactionSummary> transactions,
    InsightsPeriod period,
  ) {
    final now = DateTime.now();
    final startOfDay = FyneDateUtils.startOfDay(now);
    late final DateTime start;
    late final DateTime end;

    switch (period) {
      case InsightsPeriod.day:
        start = startOfDay;
        end = start.add(const Duration(days: 1));
        break;
      case InsightsPeriod.week:
        start = FyneDateUtils.getStartOfWeek(startOfDay);
        end = FyneDateUtils.getEndOfWeek(startOfDay);
        break;
      case InsightsPeriod.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case InsightsPeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
        break;
    }

    return transactions
        .where((tx) =>
            !tx.bookingDate.isBefore(start) && tx.bookingDate.isBefore(end))
        .toList();
  }

  List<FlSpot> _generateDynamicSpots(
      double current, List<TransactionSummary> transactions) {
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
          tx.bookingDate.isAfter(dayToReverse) &&
          tx.bookingDate.isBefore(nextDay));

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

final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier(ref);
});
