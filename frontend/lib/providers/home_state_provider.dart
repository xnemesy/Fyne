
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget_provider.dart';
import 'insights_provider.dart';
import 'scheduled_provider.dart';
import 'transaction_provider.dart';

enum FyneState {
  stableBalance,    // Equilibrio stabile
  underControl,     // Sotto controllo
  lightAttention,   // Attenzione leggera
  settlingPhase     // Fase di assestamento
}

class HomeState {
  final FyneState state;
  final String title;
  final String subtitle;
  final String contextLine;

  HomeState({
    required this.state,
    required this.title,
    required this.subtitle,
    required this.contextLine,
  });
}

final homeStateProvider = Provider<HomeState>((ref) {
  final dailyAllowance = ref.watch(dailyAllowanceProvider);
  final insights = ref.watch(insightsProvider);
  final scheduled = ref.watch(scheduledProvider).value ?? [];
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();

  FyneState fyneState;
  String title;
  String subtitle;

  // 1. Check for settling phase (first 7 days of the budget month)
  // For now, budget month aligns with calendar month, but logic is ready for custom start dates.
  final startOfBudgetMonth = DateTime(now.year, now.month, 1);
  final daysSinceStart = now.difference(startOfBudgetMonth).inDays;
  
  if (daysSinceStart < 7) {
    fyneState = FyneState.settlingPhase;
    title = "Fase di assestamento";
    subtitle = "Stai definendo il passo del mese";
  } 
  // Dynamic thresholds based on Burn Rate (velocity of spending)
  // If no history, assume a base daily burn of 30.0 for calculations
  final baseBurnRate = insights.burnRate > 0 ? insights.burnRate : 30.0;
  
  // 2. Daily budget status: warning at 80%-100%, exceeded above 100%.
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final spentToday = transactions
      .where((tx) => tx.bookingDate.isAfter(startOfDay) && tx.bookingDate.isBefore(endOfDay) && tx.amount < 0)
      .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  final dailyTarget = spentToday + dailyAllowance;
  final usage = dailyTarget > 0 ? (spentToday / dailyTarget) : 0.0;

  // Guard: if no spending data at all, don't show false "limit reached"
  if (spentToday == 0 && dailyAllowance <= 0 && transactions.isEmpty) {
    fyneState = FyneState.settlingPhase;
    title = "Nessuna spesa registrata";
    subtitle = "Aggiungi transazioni per iniziare a monitorare";
  } else if (usage >= 1.0) {
    fyneState = FyneState.lightAttention;
    title = "Limite raggiunto oggi";
    subtitle = "Hai superato il budget giornaliero";
  } else if (usage >= 0.8) {
    fyneState = FyneState.lightAttention;
    title = "Attenzione leggera";
    subtitle = "Sei vicino al limite giornaliero";
  }
  // 3. Legacy fallback on burn rate.
  else if (dailyAllowance < (baseBurnRate * 0.5)) {
    fyneState = FyneState.lightAttention;
    title = "Attenzione leggera";
    subtitle = "Qualche attenzione nei prossimi giorni";
  }
  // 4. Stable balance (allowance >= 90% of typical daily spend)
  else if (dailyAllowance >= (baseBurnRate * 0.9)) {
    fyneState = FyneState.stableBalance;
    title = "Equilibrio stabile";
    subtitle = "Nessuna azione necessaria";
  }
  // 5. Default to under control
  else {
    fyneState = FyneState.underControl;
    title = "Sotto controllo";
    subtitle = "In linea con il tuo piano";
  }

  // Context line logic
  String contextLine = "Andamento basato sulle tue abitudini recenti";
  
  final upcomingScheduled = scheduled.where((s) => s.nextOccurrence.isAfter(now) && s.nextOccurrence.isBefore(now.add(const Duration(days: 7))));
  
  if (upcomingScheduled.isNotEmpty) {
    contextLine = "Include ${upcomingScheduled.length} spese future nei prossimi 7 giorni";
  } else if (insights.expenses > insights.income && insights.income > 0) {
    contextLine = "Il saldo riflette una spesa straordinaria recente";
  } else if (dailyAllowance <= 0) {
    contextLine = "Limite giornaliero raggiunto per oggi";
  }

  return HomeState(
    state: fyneState,
    title: title,
    subtitle: subtitle,
    contextLine: contextLine,
  );
});
