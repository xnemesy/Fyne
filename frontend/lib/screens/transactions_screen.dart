import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/transaction_item.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? accountId;
  const TransactionsScreen({super.key, this.accountId});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    Account? currentAccount;
    if (widget.accountId != null && accountsAsync.hasValue) {
       currentAccount = accountsAsync.value!.firstWhere((acc) => acc.id == widget.accountId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              currentAccount?.decryptedName ?? (widget.accountId != null ? "Transazioni Conto" : "Storico Totale"),
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
            ),
            if (currentAccount != null)
              Text(
                "${currentAccount.decryptedBalance} ${currentAccount.currency}",
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A6741)),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.moreHorizontal, size: 20),
          ),
          IconButton(
            onPressed: () {
               showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddTransactionSheet(),
              );
            },
            icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF00A8FF), size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildHintCard(),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filtered = transactions.where((tx) {
                  final matchesAccount = widget.accountId == null || tx.accountId == widget.accountId;
                  final matchesSearch = tx.decryptedDescription?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true;
                  final matchesCategory = _selectedCategory == null || tx.categoryName == _selectedCategory;
                  return matchesAccount && matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                // Calculate Summary for the displayed list
                double income = 0;
                double expenses = 0;
                for (var tx in filtered) {
                  if (tx.amount > 0) income += tx.amount;
                  else expenses += tx.amount;
                }

                return Column(
                  children: [
                     _buildSummaryHeader(income, expenses),
                     Expanded(
                       child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return TransactionItem(transaction: filtered[index]);
                        },
                      ),
                     ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
              error: (err, __) => Center(child: Text("Errore: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Cerca tra le transazioni...",
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF4A6741)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip(null, "Tutte"),
                _categoryChip("Alimentari", "🥘 Alimentari"),
                _categoryChip("Shopping", "🛍️ Shopping"),
                _categoryChip("Trasporti", "🚗 Trasporti"),
                _categoryChip("Abbonamenti", "🔄 Abbonamenti"),
                _categoryChip("Wellness", "🧘 Wellness"),
                _categoryChip("Fast Food", "🍔 Fast Food"),
                _categoryChip("Altro", "📦 Altro"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF767680),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowDown, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Trascina verso il basso questa lista per aggiungere rapidamente una nuova transazione",
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1A1A).withOpacity(0.7), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.xCircle, color: const Color(0xFF1A1A1A).withOpacity(0.4), size: 20),
        ],
      ),
    );
  }

  Widget _categoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A6741) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A6741) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF1A1A1A).withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(double income, double expenses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "QUESTO MESE",
            style: GoogleFonts.inter(
              letterSpacing: 1.5,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryChip("Saldo: ${(income + expenses).toStringAsFixed(2)} €", Colors.black.withOpacity(0.05), const Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              _summaryChip("${expenses.toStringAsFixed(2)} €", const Color(0xFFD63031).withOpacity(0.1), const Color(0xFFD63031)),
              const SizedBox(width: 8),
              _summaryChip("${income.toStringAsFixed(2)} €", const Color(0xFF4A6741).withOpacity(0.1), const Color(0xFF4A6741)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 48, color: const Color(0xFF1A1A1A).withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "Nessun risultato",
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
