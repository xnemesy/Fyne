import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_card.dart';
import '../widgets/add_transaction_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'insights_screen.dart';
import 'wallet_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: CustomScrollView(
        slivers: [
          // Minimalist Editorial Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: const Color(0xFFFBFBF9),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(25, 100, 25, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bentornato,",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A1A1A).withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "La tua situazione",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _navigateTo(context, const InsightsScreen());
                },
                icon: const Icon(LucideIcons.barChart2, color: Color(0xFF1A1A1A), size: 22),
              ),
              IconButton(
                onPressed: () {
                  _navigateTo(context, const WalletScreen());
                },
                icon: const Icon(LucideIcons.wallet, color: Color(0xFF1A1A1A), size: 22),
              ),
              const SizedBox(width: 15),
            ],
          ),

          // Budget List (Bento Grid)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: budgetsAsync.when(
              data: (budgets) => budgets.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(context))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => BudgetCard(budget: budgets[index]),
                        childCount: budgets.length,
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(color: Color(0xFF4A6741)),
                  ),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    "Impossibile caricare i dati",
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTransactionSheet(),
          );
        },
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text("NUOVA SPESA", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        Icon(LucideIcons.fileSearch, size: 64, color: const Color(0xFF1A1A1A).withOpacity(0.05)),
        const SizedBox(height: 24),
        Text(
          "Nessuna attività rilevata",
          style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: Text("Configura Budget", style: GoogleFonts.inter(color: const Color(0xFF4A6741), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
