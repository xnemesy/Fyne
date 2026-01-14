import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../services/categorization_service.dart';
import '../services/crypto_service.dart';
import '../models/account.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Account? _selectedAccount;
  String? _suggestedCategoryUuid;
  String _suggestedCategoryName = "Seleziona Categoria";
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final crypto = ref.read(cryptoServiceProvider);
    final masterKey = ref.read(masterKeyProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161621),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nuova Transazione",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount Field (Optimized)
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "0.00 €",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 20),

          // Description with Smart Search
          TextField(
            controller: _descriptionController,
            onChanged: (val) async {
              _suggestCategory(val);
            },
            decoration: InputDecoration(
              labelText: "Descrizione",
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.edit, color: Colors.cyanAccent),
            ),
          ),
          if (_suggestedCategoryUuid != null)
             Padding(
               padding: const EdgeInsets.only(top: 8, left: 4),
               child: Text("💡 Suggerimento: $_suggestedCategoryName", 
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
             ),
          const SizedBox(height: 15),

          // Account Selector
          accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) return const Text("Collega un conto");
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Account>(
                    value: _selectedAccount ?? accounts.first,
                    dropdownColor: const Color(0xFF161621),
                    isExpanded: true,
                    items: accounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc,
                        child: Text(acc.decryptedName ?? "Conto", style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (acc) {
                      setState(() { _selectedAccount = acc; });
                    },
                  ),
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text("Errore carimento conti"),
          ),
          const SizedBox(height: 30),

          // Save Button (Zero-Knowledge Flow)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("SALVA TRANSAZIONE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _suggestCategory(String val) async {
    final catService = ref.read(categorizationServiceProvider);
    final budgets = ref.read(budgetsProvider).value ?? [];
    
    final uuid = await catService.categorize(val);
    
    // Find name for UI feedback
    String name = "Altro";
    for (var b in budgets) {
      if (b.categoryUuid == uuid) {
        name = b.decryptedCategoryName ?? "Sconosciuta";
        break;
      }
    }

    setState(() { 
      _suggestedCategoryUuid = uuid; 
      _suggestedCategoryName = name;
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
      
      // 3. Get proper account ID
      final accId = _selectedAccount?.id ?? (accounts.isNotEmpty ? accounts.first.id : "none");

      // 4. Send to backend
      await api.post('/api/transactions/manual', data: {
        'accountId': accId,
        'amount': double.parse(_amountController.text),
        'currency': 'EUR',
        'encryptedDescription': encryptedDesc,
        'categoryUuid': categoryUuid,
        'date': DateTime.now().toIso8601String(),
      });

      // 5. Update UI 
      ref.invalidate(accountsProvider);
      ref.invalidate(budgetsProvider);

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
