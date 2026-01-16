import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../models/account.dart';
import 'add_account_screen.dart';
import 'transactions_screen.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final authState = ref.watch(authProvider);
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'it_IT').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(accountsProvider.notifier).refresh(),
          color: const Color(0xFF4A6741),
          child: CustomScrollView(
            slivers: [
              // Custom MoneyWiz Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network('https://moneywizapp.com/favicon.ico', 
                                errorBuilder: (c, e, s) => const Icon(LucideIcons.wallet, size: 20, color: Color(0xFF4A6741)),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _headerAction(LucideIcons.sliders, () {}),
                              const SizedBox(width: 12),
                              _headerAction(LucideIcons.folderPlus, () {}),
                              const SizedBox(width: 12),
                              _headerAction(LucideIcons.plus, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddAccountScreen()),
                                );
                              }, isPrimary: true),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Conti",
                        style: GoogleFonts.lora(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        "${authState.user?.email ?? 'utente@fyne.it'} / $formattedDate",
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

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E3E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, size: 18, color: Color(0xFF8E8E93)),
                        const SizedBox(width: 10),
                        Text(
                          "Cerca",
                          style: GoogleFonts.inter(color: const Color(0xFF8E8E93), fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Summary Card (Saldo Netto / Passivo)
              SliverToBoxAdapter(
                child: accountsAsync.when(
                  data: (accounts) => _buildSummaryCard(context, accounts),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              // List of Accounts
              accountsAsync.when(
                data: (accounts) => accounts.isEmpty 
                    ? SliverToBoxAdapter(child: _buildEmptyState(context))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final account = accounts[index];
                              return _buildAccountRow(context, account);
                            },
                            childCount: accounts.length,
                          ),
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text("Errore: $err", style: const TextStyle(color: Colors.red))),
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

  Widget _buildSummaryCard(BuildContext context, List<Account> accounts) {
    double netBalance = 0;
    double liabilities = 0;

    for (var acc in accounts) {
      double bal = double.tryParse(acc.decryptedBalance ?? '0') ?? 0;
      if (bal >= 0) {
        netBalance += bal;
      } else {
        liabilities += bal.abs();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text("SALDO NETTO", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF007AFF), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text("${netBalance.toStringAsFixed(2)} €", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.black.withOpacity(0.05)),
                Expanded(
                  child: Column(
                    children: [
                      Text("PASSIVO", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF007AFF), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text("${liabilities.toStringAsFixed(2)} €", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 0, endIndent: 0),
          ListTile(
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
            },
            dense: true,
            leading: const Icon(LucideIcons.list, size: 18, color: Color(0xFF1A1A1A)),
            title: Text("Tutte le transazioni", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(BuildContext context, Account account) {
    IconData typeIcon = LucideIcons.landmark;
    if (account.type == AccountType.cash) typeIcon = LucideIcons.banknote;
    if (account.type == AccountType.credit) typeIcon = LucideIcons.creditCard;

    double bal = double.tryParse(account.decryptedBalance ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionsScreen(accountId: account.id),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon, size: 24, color: const Color(0xFF8E8E93)),
        ),
        title: Text(
          account.decryptedName ?? "Conto",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
        ),
        subtitle: Text(
          "${bal.toStringAsFixed(2)} ${account.currency}",
          style: GoogleFonts.inter(
            fontSize: 15, 
            fontWeight: FontWeight.bold, 
            color: bal >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30)
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(LucideIcons.wallet, size: 48, color: Color(0xFF8E8E93)),
            const SizedBox(height: 16),
            Text("Nessun conto configurato", style: GoogleFonts.inter(color: const Color(0xFF8E8E93))),
          ],
        ),
      ),
    );
  }
}
