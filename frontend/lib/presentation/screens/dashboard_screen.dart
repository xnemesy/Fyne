import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'wallet_screen.dart';
import 'insights_screen.dart';
import 'budgets_screen.dart';
import 'scheduled_screen.dart';
import 'settings_screen.dart';
import 'terminal_mode_screen.dart';
import '../widgets/fyne_bottom_nav.dart';
import '../widgets/add_transaction_sheet.dart';
import '../../providers/account_provider.dart';
import '../../models/account.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const WalletScreen(), // 0: Home
    const InsightsScreen(), // 1: Stats
    const SizedBox.shrink(), // 2: Placeholder per il tasto centrale
    const ScheduledTransactionsScreen(), // 3: Vault / Programmate
    const SettingsScreen(), // 4: Impostazioni
  ];

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape && accountsAsync.hasValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToTerminal(context, accountsAsync.value ?? []);
          });
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: FyneBottomNav(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index == 2) {
                // Tasto centrale: Mostra AddTransactionSheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddTransactionSheet(),
                );
              } else {
                setState(() => _selectedIndex = index);
              }
            },
          ),
        );
      },
    );
  }

  void _navigateToTerminal(BuildContext context, List<Account> accounts) {
    if (Navigator.canPop(context)) return;
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
