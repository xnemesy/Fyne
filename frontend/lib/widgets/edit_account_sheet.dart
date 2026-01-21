import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../providers/master_key_provider.dart';
import '../services/crypto_service.dart';

class EditAccountSheet extends ConsumerStatefulWidget {
  final Account account;
  const EditAccountSheet({super.key, required this.account});

  @override
  ConsumerState<EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends ConsumerState<EditAccountSheet> {
  late TextEditingController _nameController;
  late String _selectedGroup;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.decryptedName);
    _selectedGroup = widget.account.group ?? 'Personale';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildGroupChip(String label, IconData icon) {
    final isSelected = _selectedGroup == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroup = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A6741) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.05)),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4A6741).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF1A1A1A)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
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
                    "Modifica Conto",
                    style: GoogleFonts.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Color(0xFF1A1A1A), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            _buildInputLabel("NOME CONTO"),
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: _inputDecoration("Es: My Bank, Wallet Personale"),
            ),
            const SizedBox(height: 24),

            _buildInputLabel("GRUPPO"),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGroupChip("Personale", LucideIcons.user),
                  const SizedBox(width: 8),
                  _buildGroupChip("Lavoro", LucideIcons.briefcase),
                  const SizedBox(width: 8),
                  _buildGroupChip("Famiglia", LucideIcons.users),
                  const SizedBox(width: 8),
                  _buildGroupChip("Vacanza", LucideIcons.plane),
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6741),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("AGGIORNA CONTO", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isSaving ? null : _deleteAccount,
                icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFFF3B30)),
                label: Text(
                  "ELIMINA CONTO",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 13,
                    color: const Color(0xFFFF3B30),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: const Color(0xFFFF3B30).withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          letterSpacing: 2, 
          fontSize: 10, 
          fontWeight: FontWeight.bold, 
          color: const Color(0xFF1A1A1A).withOpacity(0.3)
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4A6741)),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Elimina Conto"),
        content: const Text("Sei sicuro di voler eliminare questo conto? Questa azione non può essere annullata."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULLA")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("ELIMINA", style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await ref.read(accountsProvider.notifier).deleteAccount(widget.account.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _saveAccount() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) throw Exception("Master key not found");

      final encryptedName = await crypto.encrypt(_nameController.text, masterKey);

      await ref.read(accountsProvider.notifier).updateAccount(
        widget.account.id,
        encryptedName: encryptedName,
        groupName: _selectedGroup,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
