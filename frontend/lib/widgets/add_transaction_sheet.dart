import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/api_service.dart';
import '../services/categorization_service.dart';
import '../services/crypto_service.dart';
import '../providers/isar_provider.dart';
import '../models/account.dart';

import 'package:lucide_icons/lucide_icons.dart';

import '../services/ocr_service.dart';
import 'package:intl/intl.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ocrService = OcrService();
  Account? _selectedAccount;
  String? _suggestedCategoryUuid;
  String _suggestedCategoryName = "Seleziona Categoria";
  bool _isSaving = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final result = await _ocrService.scanReceipt();
    if (result != null) {
      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(2);
      }
      if (result.date != null) {
        _descriptionController.text = "Scontrino ${DateFormat('dd/MM').format(result.date!)}";
        _suggestCategory(_descriptionController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        left: 32,
        right: 32,
        top: 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nuova Voce",
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _scanReceipt,
                    icon: const Icon(LucideIcons.camera, color: Color(0xFF4A6741), size: 22),
                    tooltip: "Scansiona scontrino",
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Color(0xFF1A1A1A), size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.lora(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "0.00 €",
              hintStyle: TextStyle(color: const Color(0xFF1A1A1A).withOpacity(0.1)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _descriptionController,
            onChanged: (val) async {
              _suggestCategory(val);
            },
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: "DESCRIZIONE",
              labelStyle: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4A6741)),
              ),
              prefixIcon: const Icon(LucideIcons.pencil, color: Color(0xFF4A6741), size: 18),
            ),
          ),
          if (_suggestedCategoryUuid != null)
             Padding(
               padding: const EdgeInsets.only(top: 12, left: 4),
               child: Row(
                 children: [
                   const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF4A6741)),
                   const SizedBox(width: 8),
                   Text("CATEGORIA: $_suggestedCategoryName", 
                              style: GoogleFonts.inter(color: const Color(0xFF4A6741), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 ],
               ),
             ),
          const SizedBox(height: 24),

          accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) return const Text("Collega un conto");
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Account>(
                    value: _selectedAccount ?? (accounts.isNotEmpty ? accounts.first : null),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 14),
                    items: accounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc,
                        child: Text(acc.decryptedName ?? "Conto", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (acc) {
                      setState(() { _selectedAccount = acc; });
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
            error: (_, __) => const Text("Errore carimento conti"),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6741),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("CONFERMA TRANSAZIONE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _suggestCategory(String val) async {
    final categorizer = ref.read(categorizationServiceProvider);
    
    final category = await categorizer.categorize(val);
    
    setState(() { 
      _suggestedCategoryUuid = category.id; 
      _suggestedCategoryName = category.name.toUpperCase();
    });
  }

  Future<void> _saveTransaction(BuildContext context) async {
    if (_amountController.text.isEmpty) return;

    setState(() { _isSaving = true; });

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final api = ref.read(apiServiceProvider);
      final masterKey = ref.read(masterKeyProvider);
      final accounts = ref.read(accountsProvider).value ?? [];

      if (masterKey == null) throw Exception("Master key not found");

      // 1. Encrypt locally
      final encryptedDesc = await crypto.encrypt(_descriptionController.text, masterKey);
      
      // 2. Use suggested category or fallback
      final categoryUuid = _suggestedCategoryUuid ?? "550e8400-e29b-41d4-a716-446655440000"; 
      
      // 3. Get proper account ID/Account
      final selectedAcc = _selectedAccount ?? (accounts.isNotEmpty ? accounts.first : null);
      if (selectedAcc == null) throw Exception("No account selected");

      // 4. Calculate New Balance (MoneyWiz dynamic)
      final amount = double.parse(_amountController.text);
      final currentBal = double.tryParse(selectedAcc.decryptedBalance ?? '0') ?? 0;
      final newBal = currentBal - amount; // Expense subtracts from balance
      final encryptedNewBalance = await crypto.encrypt(newBal.toStringAsFixed(2), masterKey);

      // 5. Send to backend
      await api.post('/api/transactions/manual', data: {
        'accountId': selectedAcc.id,
        'amount': -amount, // Save as negative for expense
        'currency': 'EUR',
        'encryptedDescription': encryptedDesc,
        'categoryUuid': categoryUuid,
        'date': DateTime.now().toIso8601String(),
        'encryptedNewBalance': encryptedNewBalance,
      });

      // 6. Update UI 
      ref.invalidate(accountsProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(transactionsProvider);

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transazione salvata e cifrata!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e")),
      );
    } finally {
      setState(() { _isSaving = false; });
    }
  }
}
