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
import '../providers/account_provider.dart';
import '../models/account.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const WalletScreen(), // Conti
    const BudgetsScreen(), // Bilanci
    const ScheduledTransactionsScreen(), // Programmate
    const InsightsScreen(), // Rapporti
    const SettingsScreen(), // Impostazioni
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF007AFF),
              unselectedItemColor: const Color(0xFF8E8E93),
              selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.creditCard),
                  label: "Conti",
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.box),
                  label: "Bilanci",
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.calendar),
                  label: "Programmate",
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.pieChart),
                  label: "Rapporti",
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.settings),
                  label: "Impostazioni",
                ),
              ],
            ),
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
