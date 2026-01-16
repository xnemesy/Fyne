import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_card.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
                            // TODO: Add budget dialog
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              budgetsAsync.when(
                data: (budgets) => budgets.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => BudgetCard(budget: budgets[index]),
                            childCount: budgets.length,
                          ),
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                ),
                error: (err, __) => SliverToBoxAdapter(
                  child: Center(child: Text("Errore: $err")),
                ),
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
          color: isPrimary ? const Color(0xFF007AFF) : const Color(0xFFE9E9EB),
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
            const Icon(LucideIcons.box, size: 48, color: Color(0xFF8E8E93)),
            const SizedBox(height: 16),
            Text("Nessun budget configurato", style: GoogleFonts.inter(color: const Color(0xFF8E8E93))),
          ],
        ),
      ),
    );
  }
}
