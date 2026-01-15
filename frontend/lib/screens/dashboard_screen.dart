import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/budget_card.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/daily_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'insights_screen.dart';
import 'wallet_screen.dart';
import '../providers/notification_scheduler.dart';
import '../providers/budget_overrun_handler.dart';
import '../widgets/budget_transfer_sheet.dart';
import '../widgets/daily_allowance_widget.dart';
import '../widgets/financial_insight_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/decrypted_value.dart';
import '../widgets/compact_cash_flow_chart.dart';
import '../widgets/subscription_list.dart';
import '../providers/account_provider.dart';
import '../providers/privacy_provider.dart';
import '../models/account.dart';
import 'terminal_mode_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    
    ref.watch(notificationSchedulerProvider);
    ref.watch(budgetOverrunHandlerProvider);

    double totalBalance = 0;
    if (accountsAsync.hasValue) {
      for (var acc in accountsAsync.value!) {
        totalBalance += double.tryParse(acc.decryptedBalance ?? '0') ?? 0;
      }
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToTerminal(context, accountsAsync.value ?? []);
          });
        }

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
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(25, 100, 25, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PATRIMONIO NETTO",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A1A1A).withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecryptedValue(
                      value: totalBalance == 0 && !accountsAsync.hasValue ? null : totalBalance.toStringAsFixed(2),
                      isLarge: true,
                      style: GoogleFonts.lora(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
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
                  ref.read(privacyProvider.notifier).togglePrivacyFilter(!ref.read(privacyProvider).isSettingsEnabled);
                },
                icon: Icon(
                  ref.watch(privacyProvider).isSettingsEnabled ? LucideIcons.shieldCheck : LucideIcons.shieldOff, 
                  color: const Color(0xFF4A6741), 
                  size: 20
                ),
                tooltip: "Privacy Blur",
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const BudgetTransferSheet(),
                  );
                },
                icon: const Icon(LucideIcons.arrowLeftRight, color: Color(0xFF4A6741), size: 20),
                tooltip: "Trasferisci budget",
              ),
              IconButton(
                onPressed: () async {
                  // Toggle mock mode locally for performance testing
                  useMockData = true;
                  ref.invalidate(transactionsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modalità Stress Test Locale (200 TX) attivata!")));
                },
                icon: const Icon(LucideIcons.beaker, color: Color(0xFF1A1A1A), size: 20),
                tooltip: "Load Test (RSA Performance)",
              ),
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

          // Daily Allowance Indicator (Intelligence Widget)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: DailyAllowanceWidget(),
            ),
          ),

          SliverToBoxAdapter(
            child: transactionsAsync.when(
              data: (txs) => FinancialInsightCard(transactions: txs),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // Cash Flow Chart
          SliverToBoxAdapter(
            child: transactionsAsync.when(
              data: (txs) => CompactCashFlowChart(transactions: txs),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // Smart Subscription List
          SliverToBoxAdapter(
            child: transactionsAsync.when(
              data: (txs) => SubscriptionList(transactions: txs),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
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

          // Recent Transactions Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TRANSAZIONI RECENTI",
                    style: GoogleFonts.inter(
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A).withOpacity(0.3),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _navigateTo(context, const WalletScreen());
                    },
                    child: Text(
                      "VEDI TUTTE",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A6741),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Transactions List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: transactionsAsync.when(
              data: (transactions) {
                final recent = transactions.take(5).toList();
                if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TransactionItem(transaction: recent[index]),
                    childCount: recent.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
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
      },
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

  void _navigateToTerminal(BuildContext context, List<Account> accounts) {
    if (Navigator.canPop(context)) return; // Avoid multiple pushes
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TerminalModeScreen(accounts: accounts),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
