import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/account_provider.dart';
import '../providers/master_key_provider.dart';
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
  final _beneficiaryController = TextEditingController();
  final _ocrService = OcrService();
  Account? _selectedAccount;
  String? _suggestedCategoryUuid;
  String _suggestedCategoryName = "Seleziona Categoria";
  bool _isSaving = false;
  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _ocrService.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final result = await _ocrService.scanReceipt();
    if (result != null) {
      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(2);
      }
      if (result.date != null) {
        setState(() {
          _selectedDate = result.date!;
        });
        _descriptionController.text = "Scontrino ${DateFormat('dd/MM').format(result.date!)}";
        _suggestCategory(_descriptionController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circularBtn(LucideIcons.x, () => Navigator.pop(context)),
                _typeSelector(),
                _saveBtn(),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(_isExpense ? "Spesa" : "Entrata", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Main Input Group
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _fieldRow(
                          icon: LucideIcons.creditCard,
                          label: _selectedAccount?.decryptedName ?? (accounts.isNotEmpty ? accounts.first.decryptedName ?? "Conto" : "Seleziona Conto"),
                          onTap: () => _showAccountPicker(accounts),
                        ),
                        const Divider(height: 1, indent: 50),
                        _amountInput(),
                        const Divider(height: 1, indent: 50),
                        _fieldInput(
                          controller: _beneficiaryController,
                          icon: LucideIcons.user,
                          hint: "Beneficiario",
                        ),
                        const Divider(height: 1, indent: 50),
                        _fieldInput(
                          controller: _descriptionController,
                          icon: LucideIcons.fileText,
                          hint: "Descrizione",
                          onChanged: _suggestCategory,
                        ),
                        const Divider(height: 1, indent: 50),
                        _fieldRow(
                          icon: LucideIcons.layoutGrid,
                          label: _suggestedCategoryName,
                          onTap: () {}, // Category picker
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Frazionata", style: GoogleFonts.inter(fontSize: 13, color: Colors.black26)),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.split, size: 14, color: Colors.black26),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date & Status Group
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _fieldRow(
                          icon: LucideIcons.calendar,
                          label: DateFormat('dd MMM yyyy HH:mm', 'it_IT').format(_selectedDate),
                          onTap: () => _selectDateTime(context),
                        ),
                        const Divider(height: 1, indent: 50),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.bookmark, size: 20, color: Colors.black26),
                              const SizedBox(width: 16),
                              _statusChip("Liquidata", true),
                              const SizedBox(width: 8),
                              _statusChip("In attesa", false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Memo Group
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.stickyNote, size: 20, color: Colors.black26),
                        const SizedBox(width: 16),
                        Expanded(child: Text("Memo", style: GoogleFonts.inter(color: Colors.black26))),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _typeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeIcon(LucideIcons.minus, _isExpense, () => setState(() => _isExpense = true)),
          _typeIcon(LucideIcons.plus, !_isExpense, () => setState(() => _isExpense = false)),
          _typeIcon(LucideIcons.arrowLeftRight, false, () {}),
          _typeIcon(LucideIcons.equal, false, () {}),
        ],
      ),
    );
  }

  Widget _typeIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
        ),
        child: Icon(icon, size: 18, color: active ? const Color(0xFFFA2C5F) : Colors.black45),
      ),
    );
  }

  Widget _saveBtn() {
    return ElevatedButton(
      onPressed: _isSaving ? null : () => _saveTransaction(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text("Salva", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
    );
  }

  Widget _fieldRow({required IconData icon, required String label, required VoidCallback onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black26),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1C1C1E)))),
            trailing ?? const Icon(LucideIcons.chevronRight, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _amountInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(LucideIcons.plusCircle, size: 20, color: Colors.black26),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: "0,00", border: InputBorder.none),
            ),
          ),
          Text("EUR", style: GoogleFonts.inter(color: Colors.black26)),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _fieldInput({required TextEditingController controller, required IconData icon, required String hint, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black26),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.inter(color: Colors.black26), border: InputBorder.none),
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4A6741) : Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: active ? Colors.white : Colors.black45, fontWeight: FontWeight.w500)),
    );
  }

  void _showAccountPicker(List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        itemCount: accounts.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(accounts[i].decryptedName ?? "Conto"),
          onTap: () {
            setState(() => _selectedAccount = accounts[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
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

      final encryptedDesc = await crypto.encrypt(_descriptionController.text, masterKey);
      final encryptedBeneficiary = await crypto.encrypt(_beneficiaryController.text, masterKey);
      final categoryUuid = _suggestedCategoryUuid ?? "550e8400-e29b-41d4-a716-446655440000"; 
      final selectedAcc = _selectedAccount ?? (accounts.isNotEmpty ? accounts.first : null);
      if (selectedAcc == null) throw Exception("No account selected");

      final amountStr = _amountController.text.replaceAll(',', '.');
      final amount = double.tryParse(amountStr) ?? 0.0;
      final currentBalStr = selectedAcc.decryptedBalance?.replaceAll(',', '.') ?? '0';
      final currentBal = double.tryParse(currentBalStr) ?? 0.0;
      final netAmount = _isExpense ? -amount : amount;
      final newBal = currentBal + netAmount; 
      final encryptedNewBalance = await crypto.encrypt(newBal.toStringAsFixed(2), masterKey);

      await api.post('/api/transactions/manual', data: {
        'accountId': selectedAcc.id,
        'amount': netAmount, 
        'currency': 'EUR',
        'encryptedDescription': encryptedDesc,
        'encryptedCounterParty': encryptedBeneficiary,
        'categoryUuid': categoryUuid,
        'date': _selectedDate.toIso8601String(),
        'encryptedNewBalance': encryptedNewBalance,
      });

      // Update local state for immediate feedback
      // selectedAcc.decryptedBalance = newBal.toStringAsFixed(2);
      ref.read(accountsProvider.notifier).updateLocalBalance(selectedAcc.id, newBal.toStringAsFixed(2));
      
      // ref.invalidate(accountsProvider);
      ref.invalidate(budgetsProvider);
      ref.refresh(transactionsProvider);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }
}
