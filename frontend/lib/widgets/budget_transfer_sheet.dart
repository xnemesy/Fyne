import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';

class BudgetTransferSheet extends ConsumerStatefulWidget {
  const BudgetTransferSheet({super.key});

  @override
  ConsumerState<BudgetTransferSheet> createState() => _BudgetTransferSheetState();
}

class _BudgetTransferSheetState extends ConsumerState<BudgetTransferSheet> {
  Budget? _sourceBudget;
  Budget? _targetBudget;
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final budgets = budgetsAsync.value ?? [];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 32,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TRASFERISCI BUDGET",
            style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          _buildDropdownLabel("DA CATEGORIA"),
          _buildBudgetDropdown(budgets, _sourceBudget, (val) => setState(() => _sourceBudget = val)),
          
          const SizedBox(height: 24),
          
          _buildDropdownLabel("A CATEGORIA"),
          _buildBudgetDropdown(budgets, _targetBudget, (val) => setState(() => _targetBudget = val)),
          
          const SizedBox(height: 24),
          
          _buildDropdownLabel("IMPORTO"),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "0.00",
              suffixText: "€",
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6741),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("CONFERMA TRASFERIMENTO", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.inter(
          letterSpacing: 2,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1A1A).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildBudgetDropdown(List<Budget> budgets, Budget? selected, ValueChanged<Budget?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Budget>(
          value: selected,
          isExpanded: true,
          hint: const Text("Seleziona categoria"),
          items: budgets.map((b) => DropdownMenuItem(
            value: b,
            child: Text(b.decryptedCategoryName ?? "Categoria"),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _handleTransfer() async {
    if (_sourceBudget == null || _targetBudget == null || _amountController.text.isEmpty) return;
    if (_sourceBudget!.id == _targetBudget!.id) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isProcessing = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/api/budgets/transfer', data: {
        'fromBudgetId': _sourceBudget!.id,
        'toBudgetId': _targetBudget!.id,
        'amount': amount,
      });

      ref.invalidate(budgetsProvider);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget trasferito con successo! 🌿")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e")),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
