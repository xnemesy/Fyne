import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/categorization_provider.dart';
import '../../services/categorization_service.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedAccountId;
  Category? _detectedCategory;
  bool _isCategorizing = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onDescriptionChanged() async {
    final text = _descriptionController.text;
    if (text.length < 3) return;

    setState(() => _isCategorizing = true);
    
    final rules = ref.read(categorizationRulesProvider).value ?? [];
    final service = ref.read(categorizationServiceProvider);
    
    final category = await service.categorize(text, customRules: rules);
    
    if (mounted) {
      setState(() {
        _detectedCategory = category;
        _isCategorizing = false;
      });
    }
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final uuid = const Uuid().v4();
    
    final tx = TransactionModel(
      uuid: uuid,
      accountId: _selectedAccountId!,
      bookingDate: DateTime.now(),
      currency: 'EUR',
      categoryName: _detectedCategory?.name ?? 'Altro',
      categoryUuid: _detectedCategory?.id,
      description: _descriptionController.text,
      createdAt: DateTime.now(),
    );

    await ref.read(transactionsProvider.notifier).addTransaction(tx);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24, right: 24, top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF9),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nuova Transazione",
                style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Amount
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF4A6741)),
            decoration: InputDecoration(
              hintText: "0,00",
              prefixText: "€ ",
              border: InputBorder.none,
              hintStyle: TextStyle(color: const Color(0xFF4A6741).withOpacity(0.3)),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: "Descrizione (es. Esselunga, Netflix...)",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              suffixIcon: _isCategorizing 
                ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
            ),
          ),
          
          if (_detectedCategory != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6741).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.tag, size: 14, color: Color(0xFF4A6741)),
                  const SizedBox(width: 6),
                  Text(
                    "Categoria: ${_detectedCategory!.name}",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A6741)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          
          // Account Selector
          Text("SELEZIONA CONTO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          accounts.when(
            data: (list) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: list.map((acc) {
                  final isSelected = _selectedAccountId == acc.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAccountId = acc.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                      ),
                      child: Text(
                        acc.name ?? "Senza nome",
                        style: GoogleFonts.inter(
                          fontSize: 13, 
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text("Errore caricamento conti"),
          ),

          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6741),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("SALVA NEL VAULT", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
