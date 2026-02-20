import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import '../../core/theme/fyne_theme.dart';
import '../widgets/feature_discovery.dart';

/// Esempio di schermata con tutorial integrato
class TransactionsScreenExample extends ConsumerWidget {
  const TransactionsScreenExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InteractiveTutorial(
      tutorialId: 'transactions_first_time',
      steps: [
        TutorialStep(
          title: 'Benvenuto nelle Transazioni',
          description:
              'Qui puoi vedere tutte le tue transazioni organizzate per data. Scorri per esplorare.',
          icon: Icons.receipt_long,
          actionHint: 'Scorri verso il basso per vedere le tue transazioni',
        ),
        TutorialStep(
          title: 'Aggiungi una Transazione',
          description:
              'Tocca il pulsante + in basso a destra per registrare una nuova entrata o uscita.',
          icon: Icons.add_circle_outline,
          targetPosition: const Offset(0, 500),
          actionHint: 'Tocca il pulsante fluttuante per provare',
        ),
        TutorialStep(
          title: 'Filtra e Cerca',
          description:
              'Usa i filtri in alto per trovare rapidamente specifiche transazioni o categorie.',
          icon: Icons.filter_list,
          actionHint: 'Prova a toccare l\'icona filtro',
        ),
        TutorialStep(
          title: 'Dettagli Transazione',
          description:
              'Tocca una transazione per vederne i dettagli completi, modificarla o eliminarla.',
          icon: Icons.info_outline,
        ),
      ],
      onComplete: () {
        print('✅ Tutorial transazioni completato!');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transazioni'),
          actions: [
            // Feature discovery sul filtro
            FeatureDiscovery(
              featureId: 'filter_button',
              title: 'Filtra Transazioni',
              description:
                  'Usa questo pulsante per filtrare le transazioni per data, categoria o importo.',
              icon: Icons.filter_list,
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Mostra filtri
                },
              ),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: 20,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            // Prima transazione ha un hint
            if (index == 0) {
              return FeatureDiscovery(
                featureId: 'transaction_item',
                title: 'Tocca per i Dettagli',
                description:
                    'Tocca una transazione per vedere tutti i dettagli, modificarla o eliminarla.',
                icon: Icons.touch_app,
                child: _buildTransactionItem(index),
              );
            }
            return _buildTransactionItem(index);
          },
        ),
        floatingActionButton: FeatureDiscovery(
          featureId: 'add_transaction_fab',
          title: 'Aggiungi Transazione',
          description:
              'Tocca qui per registrare una nuova entrata o uscita. I dati saranno cifrati automaticamente.',
          icon: Icons.add_circle_outline,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Naviga a add transaction
            },
            icon: const Icon(Icons.add),
            label: const Text('Nuova'),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FyneColors.forest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_cart, color: FyneColors.forest),
        ),
        title: Text('Transazione #$index'),
        subtitle: Text('${index + 1} Feb 2024'),
        trailing: Text(
          '€${(index * 12.50).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: FyneColors.forest,
          ),
        ),
      ),
    );
  }
}

/// Esempio di schermata Account con tutorial
class AccountDetailScreenExample extends ConsumerWidget {
  const AccountDetailScreenExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InteractiveTutorial(
      tutorialId: 'account_detail_first_time',
      steps: [
        TutorialStep(
          title: 'Dettagli Account',
          description:
              'Qui vedi il saldo attuale e lo storico movimenti di questo conto.',
          icon: Icons.account_balance,
        ),
        TutorialStep(
          title: 'Aggiorna il Saldo',
          description:
              'Tocca il saldo per aggiornarlo manualmente se necessario.',
          icon: Icons.edit,
          actionHint: 'Tocca l\'importo in alto',
        ),
        TutorialStep(
          title: 'Movimenti Recenti',
          description:
              'Scorri per vedere tutte le transazioni associate a questo conto.',
          icon: Icons.history,
        ),
      ],
      onComplete: () {
        print('✅ Tutorial account completato!');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conto Corrente'),
          actions: [
            FeatureDiscovery(
              featureId: 'account_settings',
              title: 'Impostazioni Account',
              description: 'Modifica il nome, il tipo o elimina questo conto.',
              icon: Icons.settings,
              child: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FyneColors.forest, FyneColors.forestDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FeatureDiscovery(
                  featureId: 'balance_tap',
                  title: 'Aggiorna Saldo',
                  description: 'Tocca il saldo per modificarlo manualmente.',
                  icon: Icons.edit,
                  child: GestureDetector(
                    onTap: () {
                      // Mostra dialog per aggiornare saldo
                    },
                    child: const Column(
                      children: [
                        Text(
                          'Saldo Attuale',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '€1,234.56',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Recent transactions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Movimenti Recenti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text('Transazione $index'),
                            subtitle: Text('${index + 1} Feb 2024'),
                            trailing: Text(
                              '€${(index * 25).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider per gestire lo stato dei tutorial
class TutorialStateNotifier extends StateNotifier<Map<String, bool>> {
  TutorialStateNotifier() : super({});

  void completeTutorial(String tutorialId) {
    state = {...state, tutorialId: true};
  }

  bool isTutorialCompleted(String tutorialId) {
    return state[tutorialId] ?? false;
  }

  void resetTutorial(String tutorialId) {
    final newState = Map<String, bool>.from(state);
    newState.remove(tutorialId);
    state = newState;
  }

  void resetAllTutorials() {
    state = {};
  }
}

final tutorialStateProvider =
    StateNotifierProvider<TutorialStateNotifier, Map<String, bool>>(
  (ref) => TutorialStateNotifier(),
);
