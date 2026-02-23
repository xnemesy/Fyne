import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/master_key_provider.dart';
import '../../data/repositories/account_sync_repository.dart';
import '../../services/crypto_service.dart';
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
  final _cryptoIdController = TextEditingController();
  bool _isSaving = false;
  String _selectedGroup = 'Personale';

  // Fix Bug 2: chip gruppo usa colorScheme invece di Colors.white hardcoded
  Widget _buildGroupChip(String label, IconData icon) {
    final isSelected = _selectedGroup == label;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroup = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A6741)
              // Fix Bug 2: sfondo chip non selezionato tema-aware
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : cs.outlineVariant,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A6741).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : cs.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final Map<AccountType, IconData> _typeIcons = {
    AccountType.checking: LucideIcons.landmark,
    AccountType.credit: LucideIcons.creditCard,
    AccountType.savings: LucideIcons.piggyBank,
    AccountType.loan: LucideIcons.fileText,
    AccountType.cash: LucideIcons.wallet,
    AccountType.investment: LucideIcons.trendingUp,
    AccountType.crypto: LucideIcons.bitcoin,
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
      appBar: AppBar(
        title: Text(
          _selectedType == null ? "Tipo Conto" : "Dettagli Conto",
          style: GoogleFonts.lora(
            fontWeight: FontWeight.bold,
            // Fix Bug 2: colore AppBar titolo tema-aware
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Fix Bug 2: icona back tema-aware invece di 0xFF1A1A1A hardcoded
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedType == null
            ? _buildTypeSelection()
            : _buildAccountDetails(),
      ),
    );
  }

  Widget _buildTypeSelection() {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Connessione automatica (gradient — sempre leggibile white-on-green)
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

        // Fix Bug 2: container tipi conto usa colorScheme.surface
        ...AccountType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => setState(() => _selectedType = type),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Fix Bug 2: sfondo tema-aware, leggibile in dark mode
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6741).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcons[type], color: const Color(0xFF4A6741), size: 24),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      _typeLabels[type]!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        // Fix Bug 2: testo tema-aware
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Fix Bug 2: icona chevron tema-aware
                    Icon(LucideIcons.chevronRight, color: cs.onSurface.withOpacity(0.3), size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      "SALVA CONTO",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }

  // Fix Bug 2: fillColor usa surfaceContainerHighest invece di Colors.white
  InputDecoration _inputDecoration(String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.3)),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4A6741)),
      ),
    );
  }

  Future<void> _saveAccount() async {
    if (_nameController.text.isEmpty || _balanceController.text.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text("Il vault non è ancora pronto. Riprova tra un momento.")),
          );
        return;
      }

      if (!crypto.isUnlocked) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text("Vault bloccato. Sbloccalo e riprova.")));
        return;
      }

      final result = await ref.read(accountsProvider.notifier).createAccountFromForm(
            CreateAccountCommand(
              name: _nameController.text,
              balance: _balanceController.text,
              type: _selectedType!,
              group: _selectedGroup,
              providerId: _selectedType == AccountType.crypto ? _cryptoIdController.text : null,
              currency: 'EUR',
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            result.syncStatus == AccountSyncStatus.pendingCreate
                ? "Conto salvato. Sincronizzazione cloud in background."
                : "Conto salvato e sincronizzato.",
          ),
        ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            e is StateError && e.message == 'VaultNotReady'
                ? "Il vault non è ancora pronto. Riprova tra un momento."
                : "Errore nel salvataggio. Il conto resta locale e verrà ritentato.",
          ),
        ));
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
