import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../widgets/transaction_item.dart';
import '../widgets/add_transaction_sheet.dart';

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
       try {
         currentAccount = accountsAsync.value!.firstWhere((acc) => acc.id == widget.accountId);
       } catch (e) {
         currentAccount = null;
       }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1A1A1A), size: 24),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                currentAccount?.type == AccountType.cash ? LucideIcons.banknote : LucideIcons.landmark,
                size: 20,
                color: const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentAccount?.decryptedName ?? "Transazioni",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                ),
                Text(
                  "${currentAccount?.decryptedBalance ?? '0.00'} €",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF34C759)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _headerAction(LucideIcons.moreHorizontal, () {}),
          const SizedBox(width: 8),
          _headerAction(LucideIcons.plus, () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTransactionSheet(),
            );
          }, isPrimary: true),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
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

                double income = 0;
                double expenses = 0;
                for (var tx in filtered) {
                  if (tx.amount > 0) income += tx.amount;
                  else expenses += tx.amount;
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildSummaryHeader(income, expenses),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return TransactionItem(transaction: filtered[index]);
                          },
                          childCount: filtered.length,
                        ),
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 18, color: Color(0xFF8E8E93)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Cerca",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF8E8E93),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowDown, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Trascina verso il basso questa lista per aggiungere rapidamente una nuova transazione",
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1A1A).withOpacity(0.6), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.xCircle, color: const Color(0xFF1A1A1A).withOpacity(0.2), size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double income, double expenses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Questo mese",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryChip("Saldo: ${(income + expenses).toStringAsFixed(2)} €", const Color(0xFFE9E9EB)),
              const SizedBox(width: 8),
              _summaryChip("${expenses.toStringAsFixed(2)} €", const Color(0xFFFFEBEB), textColor: const Color(0xFFFF3B30)),
              const SizedBox(width: 8),
              _summaryChip("${income.toStringAsFixed(2)} €", const Color(0xFFE9FBF0), textColor: const Color(0xFF34C759)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color bg, {Color textColor = const Color(0xFF8E8E93)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
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
