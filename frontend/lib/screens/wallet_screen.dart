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
import 'settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/wallet/wallet_summary_card.dart';
import '../widgets/daily_allowance_card.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final authState = ref.watch(authProvider);
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'it_IT').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTransactionSheet(),
          );
        },
        backgroundColor: const Color(0xFF4A6741),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
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
                               _headerAction(LucideIcons.sliders, () {
                                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                               }),
                               const SizedBox(width: 12),
                               _headerAction(LucideIcons.folderPlus, () {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gestione gruppi conti (Prossimamente)")));
                               }),
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
                        "${authState.user?.email ?? (authState.user?.isAnonymous == true ? 'Utente Verificato' : 'utente@fyne.it')} / $formattedDate",
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

              // Daily Allowance Card
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: DailyAllowanceCard(),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Summary Card (Saldo Netto / Passivo)
              const SliverToBoxAdapter(
                child: WalletSummaryCard(),
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
                              return _buildAccountRow(context, account, ref);
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
          color: isPrimary ? const Color(0xFF4A6741) : const Color(0xFFE9E9EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF1A1A1A), size: 18),
      ),
    );
  }

  Widget _buildAccountRow(BuildContext context, Account account, WidgetRef ref) {
    IconData typeIcon = LucideIcons.landmark;
    if (account.type == AccountType.cash) typeIcon = LucideIcons.banknote;
    if (account.type == AccountType.credit) typeIcon = LucideIcons.creditCard;

    final balStr = account.decryptedBalance?.replaceAll(',', '.') ?? '0';
    double bal = double.tryParse(balStr) ?? 0;

    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Elimina Conto"),
            content: const Text("Sei sicuro di voler eliminare questo conto? Questa azione non può essere annullata."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULLA")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ELIMINA", style: TextStyle(color: Color(0xFFFF3B30)))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(accountsProvider.notifier).deleteAccount(account.id);
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6741).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.wallet, size: 40, color: Color(0xFF4A6741)),
            ),
            const SizedBox(height: 24),
            Text(
              "Inizia dal tuo primo conto",
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            Text(
              "Aggiungi un conto per vedere il tuo patrimonio prendere forma.\nNessuna sincronizzazione automatica. Inserisci solo ciò che vuoi.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF1A1A1A).withOpacity(0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAccountScreen()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4A6741),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "Aggiungi conto",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
