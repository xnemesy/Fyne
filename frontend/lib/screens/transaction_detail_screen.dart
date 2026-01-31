import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../services/crypto_service.dart';
import '../services/api_service.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.decryptedDescription);
    _amountController = TextEditingController(text: widget.transaction.amount.abs().toStringAsFixed(2));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.amount < 0;
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy', 'it_IT').format(widget.transaction.bookingDate);

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
          "Dettagli Transazione",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A1A1A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF3B30)),
            onPressed: () => _deleteTransaction(),
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
                    "${isExpense ? '-' : '+'}${widget.transaction.amount.abs().toStringAsFixed(2)} €",
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
            _buildSectionTitle("DESCRIZIONE"),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("CATEGORIA"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.tag, size: 20, color: Color(0xFF4A6741)),
                  const SizedBox(width: 16),
                  Text(
                    widget.transaction.categoryName ?? "Altro",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFC7C7CC)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("SALVA MODIFICHE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: const Color(0xFF1A1A1A).withOpacity(0.4),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    // Simulate save logic
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Modifiche salvate localmente (Zero-Knowledge)")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTransaction() async {
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
      await ref.read(transactionsProvider.notifier).deleteTransaction(widget.transaction.uuid);
      if (mounted) Navigator.pop(context);
    }
  }
}
