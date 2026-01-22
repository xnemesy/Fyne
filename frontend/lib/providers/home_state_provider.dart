
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget_provider.dart';
import 'insights_provider.dart';
import 'scheduled_provider.dart';

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
  final now = DateTime.now();

  FyneState fyneState;
  String title;
  String subtitle;

  // 1. Check for settling phase (first week of the month)
  if (now.day <= 7) {
    fyneState = FyneState.settlingPhase;
    title = "Fase di assestamento";
    subtitle = "Stai definendo il passo del mese";
  } 
  // 2. Check for attention (allowance is significantly lower than average burn or very low)
  else if (dailyAllowance < 10) {
    fyneState = FyneState.lightAttention;
    title = "Attenzione leggera";
    subtitle = "Qualche attenzione nei prossimi giorni";
  }
  // 3. Stable balance (allowance is healthy)
  else if (dailyAllowance >= 20) {
    fyneState = FyneState.stableBalance;
    title = "Equilibrio stabile";
    subtitle = "Nessuna azione necessaria";
  }
  // 4. Default to under control
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
