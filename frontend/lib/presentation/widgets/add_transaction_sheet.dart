import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/haptics/fyne_haptics.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/categorization_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/categorization_service.dart';
import '../../providers/account_overview_provider.dart';
import '../../models/transaction.dart';
import 'category_picker_sheet.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _counterPartyController = TextEditingController();
  String? _selectedAccountId;
  Category? _selectedCategory;
  bool _isCategorizing = false;
  bool _isSaving = false;
  bool _isIncome = false;
  bool _isCategoryManual = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _counterPartyController.dispose();
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
        if (!_isCategoryManual) {
          _selectedCategory = category;
        }
        _isCategorizing = false;
      });
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => CategoryPickerSheet(
        selectedId: _selectedCategory?.id,
        onSelect: (category) {
          setState(() {
            _selectedCategory = category;
            _isCategoryManual = true;
          });
        },
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amount =
        FyneCurrencyFormatter.parseInput(_amountController.text) ?? 0.0;
    final description = _descriptionController.text.trim();
    final counterParty = _counterPartyController.text.trim();
    final accountId = _selectedAccountId;

    if (accountId == null) {
      _showSnackBar('Seleziona un conto');
      FyneHaptics.onError();
      return;
    }

    if (amount <= 0) {
      _showSnackBar('Inserisci un importo valido');
      FyneHaptics.onError();
      return;
    }

    if (description.isEmpty) {
      _showSnackBar('Inserisci una descrizione');
      FyneHaptics.onError();
      return;
    }

    setState(() => _isSaving = true);
    final uuid = const Uuid().v4();
    final signedAmount = _isIncome ? amount.abs() : -amount.abs();

    final tx = TransactionModel(
      uuid: uuid,
      accountId: accountId,
      bookingDate: _selectedDate,
      currency: 'EUR',
      encryptedAmount: '', // Verrà popolata dal repository
      categoryUuid: _selectedCategory?.id,
      createdAt: _selectedDate,
      updatedAt: _selectedDate,
    );

    try {
      await ref.read(transactionsProvider.notifier).addTransaction(
            tx,
            rawAmount: signedAmount.toString(),
            rawDesc: description,
            rawCounterParty: counterParty.isEmpty ? null : counterParty,
            rawCategoryName: _selectedCategory?.name,
          );
      await ref
          .read(accountsProvider.notifier)
          .applyTransactionDelta(accountId, signedAmount);
      
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletSummaryProvider);
      ref.invalidate(accountsProvider); // Invalidates the future provider explicitly
      
      // We must wait for the UI to settle before refreshing the overview 
      // which depends on Isar being fully flushed
      await Future.delayed(const Duration(milliseconds: 100));
      await ref.read(accountOverviewProvider.notifier).refresh();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pop();
      await FyneHaptics.onSaveSuccess();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Salvato nel Vault'),
          backgroundColor: FyneColors.forest,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stack) {
      debugPrint('Errore salvataggio: $e\n$stack');
      await FyneHaptics.onError();
      if (mounted) {
        _showSnackBar('Errore: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FyneColors.rust : FyneColors.forest,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Nuova Transazione",
                      style: GoogleFonts.lora(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x)),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                  decoration: InputDecoration(
                    hintText: "0,00",
                    prefixText: "€ ",
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeSelector(
                        label: "Uscita",
                        icon: Icons.arrow_upward,
                        selected: !_isIncome,
                        color: FyneColors.rust,
                        onTap: () {
                          FyneHaptics.selection();
                          setState(() => _isIncome = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeSelector(
                        label: "Entrata",
                        icon: Icons.arrow_downward,
                        selected: _isIncome,
                        color: FyneColors.forest,
                        onTap: () {
                          FyneHaptics.selection();
                          setState(() => _isIncome = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: "Descrizione (es. Esselunga, Netflix...)",
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    suffixIcon: _isCategorizing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _counterPartyController,
                  decoration: InputDecoration(
                    hintText: "Beneficiario (opzionale)",
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).brightness == Brightness.light
                              ? const ColorScheme.light(primary: FyneColors.forest, onPrimary: FyneColors.paper)
                              : const ColorScheme.dark(primary: FyneColors.forestLight, onPrimary: FyneColors.ink),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Data Transazione",
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: FyneColors.inkLight)),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMMM yyyy', 'it_IT')
                                    .format(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar_outlined,
                            color: FyneColors.inkLighter, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Categoria",
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: FyneColors.inkLight)),
                              const SizedBox(height: 2),
                              Text(
                                _selectedCategory?.name ??
                                    "Seleziona categoria",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedCategory != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: FyneColors.inkLighter),
                      ],
                    ),
                  ),
                ),

                if (_selectedCategory != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FyneColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.tag,
                            size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          "Categoria: ${_selectedCategory!.name}",
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Account Selector
                Text("SELEZIONA CONTO",
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FyneColors.inkLight)),
                const SizedBox(height: 12),
                accounts.when(
                  data: (list) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: list.map((acc) {
                        final isSelected = _selectedAccountId == acc.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAccountId = acc.id),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              acc.decryptedName ?? "Senza nome",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected 
                                   ? Theme.of(context).colorScheme.surface 
                                   : Theme.of(context).colorScheme.onSurface,
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
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FyneColors.forest,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : Text(
                            "SALVA NEL VAULT",
                            style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
