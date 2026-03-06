import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_form_provider.dart';
import '../../services/categorization_service.dart';

// ─── Costanti di tema Dark (Fyne spec) ───────────────────────────────────────

const _kForest = Color(0xFF4A6741);
const _kForestLight = Color(0xFF8FA68B);
const _kInk = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2A2A2A);
const _kSurfaceHigh = Color(0xFF383838);
const _kPaper = Color(0xFFF5F5F0);
const _kInkLight = Color(0xFF6B6B6B);
const _kRust = Color(0xFFB85450);
const _kDivider = Color(0xFF3A3A3A);

// ─── Mappa icone categorie ────────────────────────────────────────────────────

const _categoryIcons = <String, IconData>{
  'Abbonamenti': LucideIcons.tv,
  'Alimentari': LucideIcons.shoppingCart,
  'Altro': LucideIcons.tag,
  'Fast Food': LucideIcons.pizza,
  'Shopping': LucideIcons.shoppingBag,
  'Trasporti': LucideIcons.car,
  'Vizi': LucideIcons.cigarette,
  'Wellness': LucideIcons.heart,
};

// ─── Schermata principale ─────────────────────────────────────────────────────

class TransactionCreateScreen extends ConsumerStatefulWidget {
  const TransactionCreateScreen({super.key});

  @override
  ConsumerState<TransactionCreateScreen> createState() =>
      _TransactionCreateScreenState();
}

class _TransactionCreateScreenState
    extends ConsumerState<TransactionCreateScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _cpController = TextEditingController();
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus importo all'apertura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _cpController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);

    // Mostra errore come SnackBar (una sola volta, poi pulisci)
    ref.listen(transactionFormProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(next.error!),
            backgroundColor: _kRust,
            behavior: SnackBarBehavior.floating,
          ));
      }
    });

    return Scaffold(
      backgroundColor: _kInk,
      appBar: AppBar(
        backgroundColor: _kInk,
        foregroundColor: _kPaper,
        elevation: 0,
        title: Text(
          'Nuova Transazione',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _kPaper,
          ),
        ),
        actions: [
          // Pulsante salva rapido in AppBar
          if (!form.isSaving)
            TextButton(
              onPressed: form.isValid ? () => _handleSave(context, notifier) : null,
              child: Text(
                'SALVA',
                style: GoogleFonts.inter(
                  color: form.isValid ? _kForestLight : _kInkLight,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kForestLight,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Toggle Entrata / Uscita ──────────────────────────────────
            _DirectionToggle(
              isIncome: form.isIncome,
              onToggle: notifier.toggleDirection,
            ),
            const SizedBox(height: 28),

            // ── Importo ──────────────────────────────────────────────────
            _InputLabel('IMPORTO'),
            _AmountField(
              controller: _amountController,
              focusNode: _amountFocus,
              isIncome: form.isIncome,
              onChanged: notifier.setAmount,
            ),
            const SizedBox(height: 24),

            // ── Descrizione + keyword matching ───────────────────────────
            _InputLabel('DESCRIZIONE'),
            _DarkTextField(
              controller: _descController,
              hint: 'Es: Netflix, Supermercato…',
              onChanged: (v) {
                notifier.setDescription(v);
              },
            ),
            // Badge categoria auto-rilevata
            if (form.categoryName != null && _descController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap,
                        size: 12, color: _kForestLight),
                    const SizedBox(width: 4),
                    Text(
                      'Auto: ${form.categoryName}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _kForestLight,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Categoria a icone ────────────────────────────────────────
            _InputLabel('CATEGORIA'),
            _CategoryGrid(
              selected: form.categoryName,
              onSelect: notifier.setCategory,
            ),
            const SizedBox(height: 24),

            // ── Controparte ──────────────────────────────────────────────
            _InputLabel('BENEFICIARIO / PAGATORE'),
            _DarkTextField(
              controller: _cpController,
              hint: 'Es: Mario Rossi, Amazon Inc.',
              onChanged: notifier.setCounterParty,
            ),
            const SizedBox(height: 24),

            // ── Conto ────────────────────────────────────────────────────
            _InputLabel('CONTO'),
            _AccountDropdown(
              selectedAccount: form.selectedAccount,
              onSelect: notifier.setAccount,
            ),
            const SizedBox(height: 24),

            // ── Data ─────────────────────────────────────────────────────
            _InputLabel('DATA'),
            _DatePicker(
              date: form.date,
              onDateChanged: notifier.setDate,
            ),
            const SizedBox(height: 40),

            // ── Pulsante SALVA principale ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: form.isValid && !form.isSaving
                    ? () => _handleSave(context, notifier)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kForest,
                  disabledBackgroundColor: _kSurfaceHigh,
                  foregroundColor: _kPaper,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: form.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: _kPaper, strokeWidth: 2),
                      )
                    : Text(
                        'SALVA TRANSAZIONE',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(
      BuildContext context, TransactionFormNotifier notifier) async {
    try {
      await notifier.save();
      if (!mounted) return;
      Navigator.of(context).pop(true); // segnala refresh al chiamante
    } catch (_) {
      // L'errore è già nel form.error → SnackBar gestita dal listener
    }
  }
}

// ─── Sotto-widget ─────────────────────────────────────────────────────────────

/// Toggle Entrata / Uscita
class _DirectionToggle extends StatelessWidget {
  final bool isIncome;
  final VoidCallback onToggle;

  const _DirectionToggle(
      {required this.isIncome, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: '↓ USCITA',
              active: !isIncome,
              activeColor: _kRust,
              onTap: isIncome ? onToggle : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ToggleChip(
              label: '↑ ENTRATA',
              active: isIncome,
              activeColor: _kForest,
              onTap: isIncome ? null : onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? activeColor : _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? activeColor : _kDivider,
            width: active ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: active ? _kPaper : _kInkLight,
          ),
        ),
      ),
    );
  }
}

/// Campo importo con colore dinamico (verde entrata / rosso uscita)
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isIncome;
  final ValueChanged<String> onChanged;

  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.isIncome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: GoogleFonts.lora(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: isIncome ? _kForestLight : _kRust,
      ),
      decoration: InputDecoration(
        hintText: '0,00',
        hintStyle: GoogleFonts.lora(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: _kInkLight.withValues(alpha: 0.4),
        ),
        prefixText: isIncome ? '+ ' : '- ',
        prefixStyle: GoogleFonts.lora(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: isIncome ? _kForestLight : _kRust,
        ),
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isIncome ? _kForest : _kRust,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixText: 'EUR',
        suffixStyle: GoogleFonts.inter(
            fontSize: 14, color: _kInkLight, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// TextField generico dark-themed
class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: _kPaper, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: _kInkLight.withValues(alpha: 0.6), fontSize: 16),
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _kForest, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Label sezione uppercase
class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: _kInkLight,
        ),
      ),
    );
  }
}

/// Grid orizzontale di icone per le categorie
class _CategoryGrid extends ConsumerWidget {
  final String? selected;
  final void Function(String name, String uuid) onSelect;

  const _CategoryGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(categorizationServiceProvider);
    final categories = service.supportedCategories;

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final name = categories[i];
          final uuid = service.getCategoryId(name);
          final isSelected = selected == name;
          return GestureDetector(
            onTap: () => onSelect(name, uuid),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              decoration: BoxDecoration(
                color: isSelected ? _kForest : _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _kForest : _kDivider,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[name] ?? LucideIcons.tag,
                    size: 22,
                    color: isSelected ? _kPaper : _kForestLight,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _kPaper : _kInkLight,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dropdown per la selezione del conto (AsyncValue-aware)
class _AccountDropdown extends ConsumerWidget {
  final Account? selectedAccount;
  final ValueChanged<Account?> onSelect;

  const _AccountDropdown(
      {required this.selectedAccount, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kForestLight),
          ),
        ),
      ),
      error: (e, _) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('Errore caricamento conti',
              style: GoogleFonts.inter(color: _kRust, fontSize: 13)),
        ),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Nessun conto disponibile — aggiungine uno prima',
                style: GoogleFonts.inter(
                    color: _kInkLight, fontSize: 13),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Account>(
              value: selectedAccount,
              isExpanded: true,
              dropdownColor: _kSurface,
              icon: const Icon(LucideIcons.chevronDown,
                  size: 16, color: _kInkLight),
              hint: Text(
                'Seleziona un conto',
                style: GoogleFonts.inter(color: _kInkLight, fontSize: 15),
              ),
              style: GoogleFonts.inter(color: _kPaper, fontSize: 15),
              onChanged: onSelect,
              items: accounts.map((acc) {
                final name = acc.decryptedName ?? 'Conto';
                final balance = acc.decryptedBalance ?? '?';
                return DropdownMenuItem<Account>(
                  value: acc,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.landmark,
                          size: 16, color: _kForestLight),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.inter(
                                color: _kPaper,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '€$balance',
                        style: GoogleFonts.inter(
                            color: _kInkLight, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// DatePicker Cupertino dark-themed
class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  const _DatePicker(
      {required this.date, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar,
                size: 18, color: _kForestLight),
            const SizedBox(width: 12),
            Text(
              _formatDate(date),
              style: GoogleFonts.inter(
                  color: _kPaper,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: _kInkLight),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: _kPaper,
                      fontSize: 18,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: date,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: onDateChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
