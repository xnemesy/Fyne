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

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: Text(
          widget.accountId != null ? "Transazioni Conto" : "Storico Totale",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: Column(
        children: [
          _buildFilters(),
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return TransactionItem(transaction: filtered[index]);
                  },
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
