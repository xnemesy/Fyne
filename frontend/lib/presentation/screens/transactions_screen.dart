import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/transaction_provider.dart';
import '../presentation/widgets/transaction_item.dart';
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
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "I Tuoi Movimenti",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF1A1A1A)),
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
                if (summaries.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: summaries.length + (notifier.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == summaries.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
                      );
                    }

                    final summary = summaries[index];
                    return TransactionItem(
                      summary: summary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailScreen(uuid: summary.uuid),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
              error: (err, _) => Center(child: Text("Errore nel caricamento: $err")),
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
        color: const Color(0xFF4A6741).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A6741).withOpacity(0.1)),
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
                color: const Color(0xFF4A6741).withOpacity(0.8),
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
          Icon(LucideIcons.inbox, size: 48, color: const Color(0xFF1A1A1A).withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "Nessuna transazione trovata",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

