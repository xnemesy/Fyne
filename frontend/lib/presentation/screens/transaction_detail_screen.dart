import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';
import '../../presentation/providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String uuid;
  const TransactionDetailScreen({super.key, required this.uuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(transactionDetailProvider(uuid));

    return detailAsync.when(
      data: (tx) {
        if (tx == null) return _buildErrorState(context, "Transazione non trovata");
        return _TransactionDetailContent(transaction: tx);
      },
      loading: () => _buildLoadingState(context),
      error: (err, _) => _buildErrorState(context, "Errore durante la decrittazione sicura"),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4A6741)),
            const SizedBox(height: 24),
            Text(
              "Accesso al Vault Sicuro...",
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Stiamo decriptando i tuoi dati con AES-256",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1A1A1A).withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.shieldAlert, size: 48, color: Color(0xFFFF3B30)),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailContent extends ConsumerWidget {
  final TransactionModel transaction;
  const _TransactionDetailContent({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = (transaction.amount ?? 0) < 0;
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy', 'it_IT').format(transaction.bookingDate);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Dettaglio Protetto",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A1A1A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF3B30)),
            onPressed: () => _deleteTransaction(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (isExpense ? const Color(0xFFFF3B30) : const Color(0xFF34C759)).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                      size: 40,
                      color: isExpense ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${isExpense ? '-' : '+'}${transaction.amount?.abs().toStringAsFixed(2)} €",
                    style: GoogleFonts.lora(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    dateFormatted.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildInfoTile("DESCRIZIONE", transaction.description ?? "Nessuna descrizione"),
            const SizedBox(height: 24),
            _buildInfoTile("BENEFICIARIO", transaction.counterParty ?? "Sconosciuto"),
            const SizedBox(height: 24),
            _buildInfoTile("CATEGORIA", transaction.categoryName ?? "Altro", icon: LucideIcons.tag),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9EB).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: Color(0xFF4A6741), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Questa transazione è protetta da crittografia end-to-end. Solo tu puoi leggerne il contenuto.",
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1A1A1A).withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF1A1A1A).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF4A6741)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Elimina"),
        content: const Text("Sei sicuro di voler eliminare questa transazione?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ELIMINA", style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );

    if (confirm == true) {
      // In a real app we would call delete. For now just pop.
      Navigator.pop(context);
    }
  }
}
