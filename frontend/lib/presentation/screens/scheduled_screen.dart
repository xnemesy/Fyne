import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/fyne_theme.dart';
import '../../presentation/widgets/add_scheduled_sheet.dart';
import '../../presentation/widgets/fyne_shimmer.dart';
import '../../providers/scheduled_provider.dart';

class ScheduledTransactionsScreen extends ConsumerWidget {
  const ScheduledTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(scheduledProvider.notifier).refresh(),
          color: FyneColors.forest,
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
                          const Icon(LucideIcons.calendar, size: 28, color: FyneColors.forest),
                          _headerAction(context, LucideIcons.plus, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddScheduledTransactionSheet(),
                            );
                          }, isPrimary: true),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Spese future",
                        style: GoogleFonts.lora(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Pagamenti ricorrenti e spese future",
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              
              scheduledAsync.when(
                data: (transactions) => transactions.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState(context))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tx = transactions[index];
                              return _buildScheduledItem(tx, ref, context);
                            },
                            childCount: transactions.length,
                          ),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: FyneScheduledShimmer(),
                  ),
                ),
                error: (err, __) => SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text("Errore: $err", textAlign: TextAlign.center, style: GoogleFonts.inter(color: FyneColors.rust)),
                  )),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledItem(ScheduledTransaction tx, WidgetRef ref, BuildContext context) {
    return Dismissible(
      key: Key('scheduled-${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: FyneColors.rust,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(LucideIcons.trash2, color: FyneColors.paper),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Elimina Spesa", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Text("Vuoi eliminare questa spesa programmata dal Vault?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("ANNULLA", style: GoogleFonts.inter(color: FyneColors.inkLight, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("ELIMINA", style: GoogleFonts.inter(color: FyneColors.rust, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(scheduledProvider.notifier).deleteScheduledTransaction(tx.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FyneColors.ink.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getCategoryIcon(tx.categoryName),
                size: 20, 
                color: Theme.of(context).colorScheme.onSurface
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.decryptedDescription ?? "Operazione",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    "Prossima: ${DateFormat('d MMM').format(tx.nextOccurrence)} • ${tx.frequency}",
                    style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Text(
              "${tx.amount.toStringAsFixed(2)} €",
              style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
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
          color: isPrimary ? FyneColors.forest : Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? FyneColors.paper : Theme.of(context).colorScheme.onSurface, size: 18),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(LucideIcons.calendarClock, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
            const SizedBox(height: 24),
            Text(
              "Nessun pagamento programmato",
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              "Aggiungi affitti, abbonamenti o rate.",
              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return LucideIcons.calendarClock;
    
    switch (categoryName.toUpperCase()) {
      case 'CIBO':
      case 'ALIMENTARI':
      case 'FAST FOOD':
        return LucideIcons.utensils;
      case 'TRASPORTI':
        return LucideIcons.car;
      case 'ABBONAMENTI':
        return LucideIcons.creditCard;
      case 'SHOPPING':
        return LucideIcons.shoppingBag;
      case 'VIZI':
        return LucideIcons.wine;
      case 'WELLNESS':
        return LucideIcons.activity;
      case 'ALTRO':
      default:
        return LucideIcons.calendarClock;
    }
  }
}

