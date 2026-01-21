import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

enum JourneyStage {
  onboarding,      // 0 accounts
  collectingData,  // 1+ accounts, 0 transactions
  settingBudgets,  // 1+ transactions, 0 budgets
  mature           // Everything set up
}

class JourneyGuidance {
  final JourneyStage stage;
  final String? message;
  final String? nextStepCta;

  JourneyGuidance({required this.stage, this.message, this.nextStepCta});
}

final guidanceProvider = Provider<JourneyGuidance>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final budgets = ref.watch(budgetsProvider).value ?? [];

  if (accounts.isEmpty) {
    return JourneyGuidance(
      stage: JourneyStage.onboarding,
      message: "Sistema inizializzato. Configura il tuo primo conto.",
      nextStepCta: "Aggiungi Conto",
    );
  }

  if (transactions.isEmpty) {
    return JourneyGuidance(
      stage: JourneyStage.collectingData,
      message: "Analisi locale attiva. Aggiungi i tuoi movimenti.",
      nextStepCta: "Aggiungi Transazione",
    );
  }

  if (budgets.isEmpty) {
    return JourneyGuidance(
      stage: JourneyStage.settingBudgets,
      message: "Controllo dei limiti operativo. Crea un budget.",
      nextStepCta: "Crea Budget",
    );
  }

  // Mature stage: Rule of Silence
  return JourneyGuidance(
    stage: JourneyStage.mature,
    message: null,
    nextStepCta: null,
  );
});
