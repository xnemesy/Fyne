import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/budget_provider.dart';
import '../../providers/master_key_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/crypto_service.dart';
import '../../services/api_service.dart';
import '../../services/categorization_service.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({super.key});

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  final _amountController = TextEditingController();
  bool _isSaving = false;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categories = ref.read(categorizationServiceProvider).supportedCategories;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        left: 32,
        right: 32,
        top: 32,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
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
                Text(
                  "Nuovo Budget",
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, color: Theme.of(context).colorScheme.onSurface, size: 20),
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
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "0.00 €",
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "CATEGORIA",
                labelStyle: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                prefixIcon: Icon(LucideIcons.tag, color: Theme.of(context).colorScheme.primary, size: 18),
              ),
              items: categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                    : Text("SALVA BUDGET", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;
    setState(() => _isSaving = true);

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final api = ref.read(apiServiceProvider);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Il vault non è ancora pronto. Riprova tra un momento.'),
          ));
        return;
      }

      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final encryptedName = await crypto.encrypt(_selectedCategory!, scope: EncryptionScope.database, type: 'budget_category_name');
      
      final categorizationService = ref.read(categorizationServiceProvider);
      final categoryUuid = categorizationService.getCategoryId(_selectedCategory!); 

      await api.post('/api/budgets/create', data: {
        'category_uuid': categoryUuid,
        'encrypted_category_name': encryptedName,
        'limit_amount': amount,
        'current_spent': 0.0,
      });

      ref.read(budgetsProvider.notifier).refresh();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Errore nel salvataggio. Riprova.'),
        ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
