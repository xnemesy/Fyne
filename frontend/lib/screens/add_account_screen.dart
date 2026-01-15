import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart'; // sharing common providers
import '../services/crypto_service.dart';
import 'bank_selection_screen.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  AccountType? _selectedType;
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _cryptoIdController = TextEditingController(); // For crypto symbol/id
  bool _isSaving = false;

  final Map<AccountType, IconData> _typeIcons = {
    AccountType.checking: LucideIcons.landmark,
    AccountType.credit: LucideIcons.creditCard,
    AccountType.savings: LucideIcons.piggyBank,
    AccountType.loan: LucideIcons.coins,
    AccountType.cash: LucideIcons.wallet,
    AccountType.investment: LucideIcons.trendingUp,
    AccountType.crypto: LucideIcons.coins,
  };

  final Map<AccountType, String> _typeLabels = {
    AccountType.checking: "Conto Corrente",
    AccountType.credit: "Carta di Credito",
    AccountType.savings: "Risparmi",
    AccountType.loan: "Prestito / Mutuo",
    AccountType.cash: "Contante",
    AccountType.investment: "Investimenti",
    AccountType.crypto: "Crypto Wallet",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: Text(
          _selectedType == null ? "Tipo Conto" : "Dettagli Conto",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedType == null ? _buildTypeSelection() : _buildAccountDetails(),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Automatic Banking Option
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BankSelectionScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A6741), Color(0xFF2D3436)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6741).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.zap, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Connessione Automatica",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Collega la tua banca reale",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.chevronRight, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
        
        _buildInputLabel("O AGGIUNGI MANUALMENTE"),
        const SizedBox(height: 8),

        ...AccountType.values.map((type) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => setState(() => _selectedType = type),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6741).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_typeIcons[type], color: const Color(0xFF4A6741), size: 24),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _typeLabels[type]!,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.chevronRight, color: Colors.black.withOpacity(0.2), size: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
      ],
    );
  }

  Widget _buildAccountDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel("NOME CONTO"),
          TextField(
            controller: _nameController,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            decoration: _inputDecoration("Es: My Bank, Wallet Personale"),
          ),
          const SizedBox(height: 24),
          
          _buildInputLabel(_selectedType == AccountType.crypto ? "QUANTITÀ" : "SALDO INIZIALE"),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: _inputDecoration("0.00"),
          ),
          const SizedBox(height: 24),

          if (_selectedType == AccountType.crypto) ...[
            _buildInputLabel("COINGECKO ID (es: bitcoin, ethereum)"),
            TextField(
              controller: _cryptoIdController,
              decoration: _inputDecoration("id dalla url di coingecko"),
            ),
            const SizedBox(height: 24),
          ],

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
                  : Text("SALVA CONTO", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
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

  Future<void> _saveAccount() async {
    if (_nameController.text.isEmpty || _balanceController.text.isEmpty) return;

    setState(() { _isSaving = true; });

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final api = ref.read(apiServiceProvider);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) throw Exception("Master key not found");

      // 1. Encrypt details
      final encryptedName = await crypto.encrypt(_nameController.text, masterKey);
      final encryptedBalance = await crypto.encrypt(_balanceController.text, masterKey);
      
      // 2. Metadata (potentially including crypto ID)
      // For now, let's keep it simple and add it to a metadata field if backend supports or just providerId
      
      // 3. Post to backend
      await api.post('/api/accounts', data: {
        'encrypted_name': encryptedName,
        'encrypted_balance': encryptedBalance,
        'currency': 'EUR',
        'type': _selectedType!.name,
        'provider_id': _selectedType == AccountType.crypto ? _cryptoIdController.text : null,
      });

      ref.invalidate(accountsProvider);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      setState(() { _isSaving = false; });
    }
  }
}
