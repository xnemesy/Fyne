import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_card.dart';
import '../widgets/add_budget_sheet.dart';
import '../widgets/daily_allowance_card.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(budgetsProvider.notifier).refresh(),
          color: const Color(0xFF4A6741),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(LucideIcons.box, size: 28, color: Color(0xFF4A6741)),
                          _headerAction(LucideIcons.plus, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddBudgetSheet(),
                            );
                          }, isPrimary: true),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Bilanci",
                        style: GoogleFonts.lora(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        "Gestisci i tuoi limiti di spesa per categoria",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1A1A1A).withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: DailyAllowanceCard(),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              Consumer(
                builder: (context, ref, child) {
                  final budgetsAsync = ref.watch(budgetsProvider);
                  final summaries = ref.watch(budgetSummaryProvider);

                  return budgetsAsync.when(
                    data: (budgets) => summaries.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState())
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final summary = summaries[index];
                                  return Dismissible(
                                    key: Key(summary.budget.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3B30),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(LucideIcons.trash2, color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Elimina Budget"),
                                          content: const Text("Vuoi eliminare questo budget?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULLA")),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ELIMINA", style: TextStyle(color: Color(0xFFFF3B30)))),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) {
                                      ref.read(budgetsProvider.notifier).deleteBudget(summary.budget.id);
                                    },
                                    child: BudgetCard(status: summary),
                                  );
                                },
                                childCount: summaries.length,
                              ),
                            ),
                          ),
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                    ),
                    error: (err, __) => SliverToBoxAdapter(
                      child: Center(child: Text("Errore: $err")),
                    ),
                  );
                },
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF4A6741) : const Color(0xFFE9E9EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF1A1A1A), size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6741).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.box, size: 40, color: Color(0xFF4A6741)),
            ),
            const SizedBox(height: 24),
            Text(
              "Nessun budget attivo",
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            Text(
              "Definisci i tuoi limiti di spesa quando sei pronto",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF1A1A1A).withOpacity(0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
