import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/fyne_shimmer.dart';
import '../widgets/transaction_item.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? accountId;
  const TransactionsScreen({super.key, this.accountId});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(transactionsNotifierProvider.notifier);
      if (notifier.hasMore) {
        HapticFeedback.lightImpact(); // Feedback tattile premium
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsNotifierProvider);
    final notifier = ref.read(transactionsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.accountId != null ? IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          "I Tuoi Movimenti",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw, size: 20),
            onPressed: () => ref.read(transactionsNotifierProvider.notifier).refresh(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: transactionsAsync.when(
              data: (summaries) {
                final visibleSummaries = widget.accountId == null
                    ? summaries
                    : summaries.where((tx) => tx.accountId == widget.accountId).toList();

                if (visibleSummaries.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  key: ValueKey(widget.accountId ?? 'all-transactions'),
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: visibleSummaries.length + (notifier.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == visibleSummaries.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                      );
                    }

                    final summary = visibleSummaries[index];
                    return Dismissible(
                      key: Key('tx-${summary.uuid}'),
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
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text("Elimina Movimento", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            content: Text("Sei sicuro di voler eliminare questo movimento?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("ANNULLA", style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("ELIMINA", style: GoogleFonts.inter(color: const Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        HapticFeedback.mediumImpact();
                        notifier.deleteTransaction(summary.uuid);
                      },
                      child: TransactionItem(
                        key: ValueKey(summary.uuid),
                        summary: summary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailScreen(uuid: summary.uuid),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                itemCount: 8,
                itemBuilder: (_, __) => const FyneTransactionShimmer(),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFA0665F), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        "Errore caricamento: $err",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(transactionsProvider.notifier).refresh(),
                        child: const Text("Riprova"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6741).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A6741).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.lock, color: Color(0xFF4A6741), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Privacy First: i dettagli sensibili vengono decriptati solo quando apri una transazione.",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A6741).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Nessuna transazione trovata",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
