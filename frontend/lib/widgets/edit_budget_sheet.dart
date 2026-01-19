
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/budget_provider.dart';
import '../services/api_service.dart';
import '../models/budget.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  final Budget budget;
  const EditBudgetSheet({super.key, required this.budget});

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.budget.limitAmount.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Modifica ${widget.budget.decryptedCategoryName ?? 'Budget'}",
                    style: GoogleFonts.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Color(0xFF1A1A1A), size: 20),
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
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6741),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("AGGIORNA BUDGET", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (_amountController.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiServiceProvider);
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

      await api.put('/api/budgets/${widget.budget.id}', data: {
        'limitAmount': amount, 
      });
      // Note: backend route in budgets.js uses "limitAmount" (camelCase) in destructuring: const { limitAmount } = req.body;
      // But let's check the previous step view_file of budgets.js content:
      // router.put('/:id', verifyToken, async (req, res) => {
      //     const { limitAmount } = req.body;
      
      // So we send 'limitAmount'.

      ref.read(budgetsProvider.notifier).refresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
