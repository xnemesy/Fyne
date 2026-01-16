import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../services/crypto_service.dart';
import '../services/api_service.dart';
import '../providers/budget_provider.dart';

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
                Text(
                  "Programma Spesa",
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
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
            const SizedBox(height: 32),
            TextField(
              controller: _descriptionController,
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
                  borderSide: const BorderSide(color: Color(0xFF007AFF)),
                ),
                prefixIcon: const Icon(LucideIcons.calendar, color: Color(0xFF007AFF), size: 18),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "FREQUENZA",
              style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.3)),
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
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
            color: active ? const Color(0xFF007AFF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? Colors.transparent : Colors.black.withOpacity(0.05)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: active ? Colors.white : const Color(0xFF1A1A1A).withOpacity(0.4)),
          ),
        ),
      ),
    );
  }

  Future<void> _saveScheduled() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final api = ref.read(apiServiceProvider);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) throw Exception("Master key not found");

      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final encryptedDesc = await crypto.encrypt(_descriptionController.text, masterKey);

      await api.post('/api/scheduled-transactions', data: {
        'encrypted_description': encryptedDesc,
        'amount': -amount, // Assuming it's an expense
        'currency': 'EUR',
        'frequency': _frequency,
        'next_occurrence': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transazione programmata correttamente!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
