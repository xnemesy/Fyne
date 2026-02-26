import 'package:flutter/material.dart';
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

// ─── Enum Periodo ─────────────────────────────────────────────────────────────

enum InsightsPeriod { day, week, month, year }

// ─── Data class per il breakdown spese per categoria ─────────────────────────

/// Aggrega importo e colore per una singola categoria di spesa.
/// Usato dal `CategoryPieChart` per disegnare le fette.
class CategoryAmount {
  final String name;
  final double amount;
  final Color color;

  const CategoryAmount({
    required this.name,
    required this.amount,
    required this.color,
  });
}

// Palette colori per le categorie (varianti tono-verde Fyne)
const _categoryColors = <String, Color>{
  'Alimentari':  Color(0xFF4A6741),
  'Abbonamenti': Color(0xFF7A9E74),
  'Shopping':    Color(0xFF355030),
  'Fast Food':   Color(0xFFB85450),
  'Trasporti':   Color(0xFF8FA68B),
  'Wellness':    Color(0xFF5A8F52),
  'Vizi':        Color(0xFF9C4A40),
  'Altro':       Color(0xFF6B6B6B),
};

Color _colorForCategory(String name) =>
    _categoryColors[name] ?? const Color(0xFF6B6B6B);

// ─── InsightsState ────────────────────────────────────────────────────────────

class InsightsState {
  final double netWorth;
  final List<FlSpot> netWorthHistory;
  final double burnRate;
  final double burnRateTrend;
  final double income;
  final double expenses;
  final double savings;
  final double savingsRate;
  final List<BudgetStatus> topCategories;
  /// Breakdown spese per categoria — alimenta il PieChart
  final List<CategoryAmount> categoryBreakdown;
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
    this.categoryBreakdown = const [],
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
    List<CategoryAmount>? categoryBreakdown,
    bool? isLoading,
    InsightsPeriod? selectedPeriod,
  }) {
    return InsightsState(
      netWorth:          netWorth          ?? this.netWorth,
      netWorthHistory:   netWorthHistory   ?? this.netWorthHistory,
      burnRate:          burnRate          ?? this.burnRate,
      burnRateTrend:     burnRateTrend     ?? this.burnRateTrend,
      income:            income            ?? this.income,
      expenses:          expenses          ?? this.expenses,
      savings:           savings           ?? this.savings,
      savingsRate:       savingsRate       ?? this.savingsRate,
      topCategories:     topCategories     ?? this.topCategories,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      isLoading:         isLoading         ?? this.isLoading,
      selectedPeriod:    selectedPeriod    ?? this.selectedPeriod,
    );
  }
}

// ─── InsightsNotifier ─────────────────────────────────────────────────────────

class InsightsNotifier extends StateNotifier<InsightsState> {
  final Ref ref;

  InsightsNotifier(this.ref) : super(InsightsState()) {
    _init();
  }

  void _init() {
    ref.listen<AsyncValue<List<Account>>>(
        accountsProvider, (_, __) => _recalculate());
    ref.listen<AsyncValue<List<TransactionSummary>>>(
        transactionsProvider, (_, __) => _recalculate());
    ref.listen<List<BudgetStatus>>(
        budgetSummaryProvider, (_, __) => _recalculate());
    _recalculate();
  }

  Future<void> _recalculate() async {
    final repo = ref.read(transactionRepositoryProvider);
    final accountsState      = ref.read(accountsProvider);
    final transactionsState  = ref.read(transactionsProvider);
    final budgetSummaries    = ref.read(budgetSummaryProvider);

    if (accountsState.isLoading || transactionsState.isLoading || repo == null) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final accounts     = accountsState.value ?? [];
    final transactions = transactionsState.value ?? [];
    final periodTxs    = _filterByPeriod(transactions, state.selectedPeriod);

    // 1. Patrimonio netto (somma saldi decifrati)
    double currentNetWorth = 0;
    for (final acc in accounts) {
      final balStr = acc.decryptedBalance?.replaceAll(',', '.') ?? '0';
      currentNetWorth += double.tryParse(balStr) ?? 0;
    }

    // 2. Storia patrimonio netto (ultimi 7 giorni)
    final historySpots = _generateDynamicSpots(currentNetWorth, transactions);

    // 3. Burn rate rolling 30 giorni
    final now             = DateTime.now();
    final thirtyDaysAgo   = now.subtract(const Duration(days: 30));
    final totalSpent30    = await repo.getTotalSpentInRange(thirtyDaysAgo, now);
    final dailyBurn       = totalSpent30 / 30;

    // 4. Cash Flow del periodo selezionato
    double income   = 0;
    double expenses = 0;
    for (final tx in periodTxs) {
      if (tx.amount > 0) income   += tx.amount;
      else               expenses += tx.amount.abs();
    }
    final savings     = income - expenses;
    final savingsRate = income > 0 ? (savings / income) : 0.0;

    // 5. Top categorie per budget
    final sortedSummaries = List<BudgetStatus>.from(budgetSummaries)
      ..sort((a, b) => b.spent.compareTo(a.spent));

    // 6. Breakdown spese per categoria (alimenta il PieChart)
    final breakdown = _buildCategoryBreakdown(periodTxs);

    state = state.copyWith(
      netWorth:          currentNetWorth,
      netWorthHistory:   historySpots,
      burnRate:          dailyBurn,
      burnRateTrend:     -5.0, // placeholder — sostituire con calcolo storico
      income:            income,
      expenses:          expenses,
      savings:           savings,
      savingsRate:       savingsRate,
      topCategories:     sortedSummaries,
      categoryBreakdown: breakdown,
      isLoading:         false,
    );
  }

  void setPeriod(InsightsPeriod period) {
    if (state.selectedPeriod == period) return;
    state = state.copyWith(selectedPeriod: period, isLoading: true);
    _recalculate();
  }

  // ── Helper: breakdown spese aggregate per categoria ──────────────────────

  List<CategoryAmount> _buildCategoryBreakdown(List<TransactionSummary> txs) {
    final Map<String, double> byCategory = {};
    for (final tx in txs.where((t) => t.amount < 0)) {
      final cat = tx.categoryName ?? 'Altro';
      byCategory.update(cat, (v) => v + tx.amount.abs(),
          ifAbsent: () => tx.amount.abs());
    }
    // Ordina per importo decrescente
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .map((e) => CategoryAmount(
              name:   e.key,
              amount: e.value,
              color:  _colorForCategory(e.key),
            ))
        .toList();
  }

  // ── Helper: filtro per periodo ────────────────────────────────────────────

  List<TransactionSummary> _filterByPeriod(
      List<TransactionSummary> transactions, InsightsPeriod period) {
    final now        = DateTime.now();
    final startOfDay = FyneDateUtils.startOfDay(now);
    late final DateTime start, end;

    switch (period) {
      case InsightsPeriod.day:
        start = startOfDay;
        end   = start.add(const Duration(days: 1));
      case InsightsPeriod.week:
        start = FyneDateUtils.getStartOfWeek(startOfDay);
        end   = FyneDateUtils.getEndOfWeek(startOfDay);
      case InsightsPeriod.month:
        start = DateTime(now.year, now.month, 1);
        end   = DateTime(now.year, now.month + 1, 1);
      case InsightsPeriod.year:
        start = DateTime(now.year, 1, 1);
        end   = DateTime(now.year + 1, 1, 1);
    }

    return transactions
        .where((tx) =>
            !tx.bookingDate.isBefore(start) && tx.bookingDate.isBefore(end))
        .toList();
  }

  // ── Helper: storia patrimoniale (7 giorni) ────────────────────────────────

  List<FlSpot> _generateDynamicSpots(
      double current, List<TransactionSummary> transactions) {
    final List<FlSpot> spots = [];
    double balance = current;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    spots.add(FlSpot(6, balance));

    for (int i = 1; i <= 6; i++) {
      final day     = today.subtract(Duration(days: i - 1));
      final nextDay = day.add(const Duration(days: 1));
      final dayTxs  = transactions.where((tx) =>
          tx.bookingDate.isAfter(day) && tx.bookingDate.isBefore(nextDay));
      for (final tx in dayTxs) {
        balance -= tx.amount;
      }
      spots.add(FlSpot((6 - i).toDouble(), balance));
    }
    return spots.reversed.toList();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier(ref);
});
