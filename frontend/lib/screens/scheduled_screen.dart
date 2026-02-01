import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../presentation/widgets/add_scheduled_sheet.dart';
import '../presentation/widgets/transaction_item.dart'; // Reusing helper methods from here or similar 
import '../providers/scheduled_provider.dart';
import '../services/categorization_service.dart'; // Need this if we use Category model directly? No, string based.

class ScheduledTransactionsScreen extends ConsumerWidget {
  const ScheduledTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(scheduledProvider.notifier).refresh(),
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
                          const Icon(LucideIcons.calendar, size: 28, color: Color(0xFF4A6741)),
                          _headerAction(LucideIcons.plus, () {
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
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        "Pagamenti ricorrenti e spese future",
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
              
              scheduledAsync.when(
                data: (transactions) => transactions.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tx = transactions[index];
                              return _buildScheduledItem(tx);
                            },
                            childCount: transactions.length,
                          ),
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                ),
                error: (err, __) => SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text("Errore: $err", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
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

  Widget _buildScheduledItem(ScheduledTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(tx.categoryName),
              size: 20, 
              color: const Color(0xFF1A1A1A)
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
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
                ),
              ],
            ),
          ),
          Text(
            "${tx.amount.toStringAsFixed(2)} €",
            style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1A1A1A)),
          ),
        ],
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
            Icon(LucideIcons.calendarClock, size: 64, color: const Color(0xFF1A1A1A).withOpacity(0.05)),
            const SizedBox(height: 24),
            Text(
              "Nessun pagamento programmato",
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              "Aggiungi affitti, abbonamenti o rate.",
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
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

