import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/account_provider.dart';
import '../presentation/providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/preferences_provider.dart';

class MilestoneListener extends ConsumerWidget {
  final Widget child;

  const MilestoneListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    // Listen for the first account
    ref.listen(accountsProvider, (previous, next) {
      if (!prefs.milestoneAccountReached && 
          previous?.value?.isEmpty == true && 
          next.value?.isNotEmpty == true) {
        ref.read(preferencesProvider.notifier).markAccountReached();
        _showMilestone(context, "Sistema inizializzato.");
      }
    });

    // Listen for the first transaction
    ref.listen(transactionsProvider, (previous, next) {
      if (!prefs.milestoneTransactionReached && 
          previous?.value?.isEmpty == true && 
          next.value?.isNotEmpty == true) {
         ref.read(preferencesProvider.notifier).markTransactionReached();
         _showMilestone(context, "Analisi locale attiva.");
      }
    });

    // Listen for the first budget
    ref.listen(budgetsProvider, (previous, next) {
      if (!prefs.milestoneBudgetReached && 
          previous?.value?.isEmpty == true && 
          next.value?.isNotEmpty == true) {
        ref.read(preferencesProvider.notifier).markBudgetReached();
        _showMilestone(context, "Controllo dei limiti operativo.");
      }
    });

    return child;
  }

  void _showMilestone(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

