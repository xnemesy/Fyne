import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/master_key_provider.dart';
import '../../services/crypto_service.dart';
import '../../services/api_service.dart';
import '../../providers/scheduled_provider.dart';

class AddScheduledTransactionSheet extends ConsumerStatefulWidget {
  const AddScheduledTransactionSheet({super.key});

  @override
  ConsumerState<AddScheduledTransactionSheet> createState() => _AddScheduledTransactionSheetState();
}

class _AddScheduledTransactionSheetState extends ConsumerState<AddScheduledTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _frequency = 'MONTHLY';
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
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
                  "Nuova spesa futura",
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
            Center(
              child: Text(
                "Inserisci solo se ha senso per te",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _descriptionController,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "DESCRIZIONE",
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
                prefixIcon: Icon(LucideIcons.calendar, color: Theme.of(context).colorScheme.primary, size: 18),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "INIZIO",
              style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendarDays, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.chevronDown, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "FREQUENZA",
              style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _freqBtn("SETTIMANALE", "WEEKLY"),
                const SizedBox(width: 8),
                _freqBtn("MENSILE", "MONTHLY"),
                const SizedBox(width: 8),
                _freqBtn("ANNUALE", "YEARLY"),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveScheduled,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                    : Text("PROGRAMMA ORA", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _freqBtn(String label, String value) {
    final active = _frequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.onSurface : Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? Colors.transparent : Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: active ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.light 
               ? const ColorScheme.light(primary: Color(0xFF4A6741), onPrimary: Colors.white)
               : const ColorScheme.dark(primary: Color(0xFF8FA68B), onPrimary: Color(0xFF1A1A1A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveScheduled() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) return;
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
      final encryptedDesc = await crypto.encrypt(_descriptionController.text, scope: EncryptionScope.database, type: 'scheduled_description');

      await api.post('/api/scheduled-transactions', data: {
        'encrypted_description': encryptedDesc,
        'amount': -amount.abs(),
        'currency': 'EUR',
        'frequency': _frequency,
        'next_occurrence': _selectedDate.toIso8601String(),
      });

      ref.read(scheduledProvider.notifier).refresh();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transazione programmata correttamente!')));
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
