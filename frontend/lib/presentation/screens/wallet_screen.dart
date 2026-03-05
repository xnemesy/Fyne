import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/account.dart';
import 'add_account_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/fyne_shimmer.dart';
import '../widgets/edit_account_sheet.dart';
import '../widgets/wallet/wallet_summary_card.dart';
import '../widgets/home_compass_widget.dart';
import '../../providers/transaction_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final authState = ref.watch(authProvider);
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'it_IT').format(now);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (accountsAsync.hasValue &&
              accountsAsync.value!.isNotEmpty &&
              transactionsAsync.hasValue &&
              transactionsAsync.value!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  // Bug B: era onSurface (chiaro in dark mode) → surface (scuro in dark mode)
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Aggiungi la tua prima spesa",
                      style: GoogleFonts.inter(
                        // Bug B: era Colors.white hardcoded → onSurface per contrasto corretto
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.arrowDown,
                        color: Theme.of(context).colorScheme.onSurface, size: 16),
                  ],
                ),
              ),
            ),
          FloatingActionButton(
            heroTag: 'add_tx_fab',
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
        ],
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
                            // Theme-aware: evita cerchio bianco in dark mode
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network('https://moneywizapp.com/favicon.ico', 
                                errorBuilder: (c, e, s) => const Icon(LucideIcons.wallet, size: 20, color: Color(0xFF4A6741)),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                               _headerAction(context, LucideIcons.sliders, () {
                                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                               }),
                               const SizedBox(width: 12),
                               _headerAction(context, LucideIcons.folderPlus, () {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gestione gruppi conti (Prossimamente)")));
                               }),
                              const SizedBox(width: 12),
                              _headerAction(context, LucideIcons.plus, () {
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
                      // Removed "Conti" title as per Home philosophy
                      Text(
                        "${authState.user?.email ?? (authState.user?.isAnonymous == true ? 'Utente Verificato' : 'utente@fyne.it')} / $formattedDate",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // BLOCK 1, 2, 3: THE COMPASS
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 20),
                  child: HomeCompassWidget(),
                ),
              ),

              // Wallet Summary Card (Saldo Netto / Passivo)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: WalletSummaryCard(),
                ),
              ),

              // Standalone CTA: Tutte le transazioni
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      // Theme-aware: surface del tema (scuro in dark, chiaro in light)
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.list, size: 18,
                            color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 12),
                        Text(
                          "Tutte le transazioni",
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)
                        ),
                        const Spacer(),
                        Icon(LucideIcons.chevronRight, size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                ),
              ),

              // Dettagli Conti (Sotto i 3 blocchi principali)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "I TUOI CONTI",
                    style: GoogleFonts.inter(
                      letterSpacing: 2,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),

              // List of Accounts (Minimal)
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
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const FyneAccountShimmer(),
                    childCount: 4,
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text("Errore: $err", style: const TextStyle(color: Colors.red))),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAction(BuildContext context, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // Theme-aware: sfondo scuro in dark mode, grigio chiaro in light mode
        color: isPrimary ? const Color(0xFF4A6741) : Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : Theme.of(context).colorScheme.onSurface, size: 18),
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
          // Theme-aware: surface scura in dark mode, chiara in light mode
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => EditAccountSheet(account: account),
            );
          },
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Theme-aware: sfondo icona conto (neutro in dark e light)
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, size: 24, color: const Color(0xFF8E8E93)),
          ),
          title: Text(
            account.decryptedName ?? "Conto",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
                color: const Color(0xFF4A6741).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.wallet, size: 40, color: Color(0xFF4A6741)),
            ),
            const SizedBox(height: 24),
            Text(
              "Inizia dal tuo primo conto",
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              "Aggiungi un conto per vedere il tuo patrimonio prendere forma.\nNon c'è fretta, inizia con quello che usi di più.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Icon(LucideIcons.arrowUp, color: Color(0xFF4A6741), size: 24),
            const SizedBox(height: 16),
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

