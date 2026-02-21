import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/seed_service.dart';
import 'recovery_screen.dart';

/// Wizard obbligatorio al primo accesso.
/// 4 step: Seed Display → Backup Confirm → Seed Verify → Biometric Setup.
class MasterKeyWizard extends ConsumerStatefulWidget {
  const MasterKeyWizard({super.key});

  @override
  ConsumerState<MasterKeyWizard> createState() => _MasterKeyWizardState();
}

class _MasterKeyWizardState extends ConsumerState<MasterKeyWizard> {
  final _pageController = PageController();
  final _seedService = SeedService();
  
  late final String _mnemonic;
  late final List<String> _words;
  
  int _currentStep = 0;
  
  // Step 2: Backup confirmation — 3 checkbox separati
  bool _confirmedPhysicalBackup = false;
  bool _confirmedUnderstanding = false;
  bool _confirmedResponsibility = false;
  
  bool get _allBackupConfirmed =>
      _confirmedPhysicalBackup && _confirmedUnderstanding && _confirmedResponsibility;
  
  // Step 1: Clipboard (Countdown Fix)
  Timer? _clipboardClearTimer;
  Timer? _countdownTimer;
  bool _seedCopied = false;
  bool _seedRevealed = false;
  int _secondsRemaining = 60;

  // Step 3: Verification (Randomization Fix)
  List<int> _wordsToVerify = [];
  final Map<int, TextEditingController> _verifyControllers = {};
  final Map<int, bool> _verificationStatus = {};
  
  // Step 4: Biometric
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  
  // Final
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _mnemonic = _seedService.generateMnemonic();
    _words = _seedService.mnemonicToWords(_mnemonic);
    
    // Fix Randomization: Unique Indices
    _wordsToVerify = _generateUniqueRandomIndices(3, 12);
    for (final index in _wordsToVerify) {
      _verifyControllers[index] = TextEditingController();
    }
    
    _checkBiometric();
  }

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    _countdownTimer?.cancel();
    _pageController.dispose();
    for (final c in _verifyControllers.values) c.dispose();
    super.dispose();
  }

  // --- Helpers ---
  List<int> _generateUniqueRandomIndices(int count, int max) {
    final random = Random();
    final indices = <int>{}; // Set per garantire unicità
    while (indices.length < count) {
      indices.add(random.nextInt(max));
    }
    return indices.toList()..sort();
  }

  void _verifyWord(int index) {
    final input = _verifyControllers[index]!.text.trim().toLowerCase();
    final correct = _words[index].toLowerCase();
    
    setState(() {
      _verificationStatus[index] = input == correct;
    });
    
    if (_verificationStatus[index] == true) {
      HapticFeedback.lightImpact();
    } else if (_verificationStatus[index] == false) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _checkBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      final available = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = available && isDeviceSupported);
      }
    } catch (_) {
      // Biometric not available
    }
  }

  void _nextPage() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(authProvider.notifier).completeWizardSetup(
        _mnemonic,
        biometricEnabled: _biometricEnabled,
      );
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Errore nella configurazione: ${e.toString()}'),
          ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FyneColors.paper,
      // Fix Recovery Link
      appBar: AppBar(
        title: Text('Configurazione Vault', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecoveryScreen())),
            icon: const Icon(Icons.key, color: FyneColors.forest),
            label: const Text('Recupera', style: TextStyle(color: FyneColors.forest)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSeedDisplayStep(),
                  _buildBackupConfirmStep(),
                  _buildSeedVerifyStep(),
                  _buildBiometricStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Progress Bar
  // ─────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} di 4',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance back button
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? FyneColors.forest
                        : FyneColors.paperDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 1: Seed Phrase Display
  // ─────────────────────────────────────────────

  Widget _buildSeedDisplayStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recovery link per utenti che reinstallano
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FyneColors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FyneColors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, color: FyneColors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hai già un account?',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RecoveryScreen()),
                        ),
                        child: Text(
                          'Recupera con le tue 12 parole \u2192',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: FyneColors.forest,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'La Tua Chiave\ndi Recupero',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Queste 12 parole sono l\'unico modo per recuperare i tuoi dati. Salvale in un posto sicuro.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // Warning
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FyneColors.rust.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FyneColors.rust.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: FyneColors.rust, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Non condividere queste parole con nessuno. Chi le possiede ha accesso ai tuoi dati.',
                    style: GoogleFonts.inter(fontSize: 12, color: FyneColors.rust, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seed phrase grid
          GestureDetector(
            onTap: () {
              setState(() => _seedRevealed = !_seedRevealed);
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FyneColors.paperDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, i) {
                      return Container(
                        decoration: BoxDecoration(
                          color: FyneColors.forest.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FyneColors.forest.withValues(alpha: 0.15)),
                        ),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${i + 1}. ',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)er,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: _seedRevealed ? _words[i] : '••••',
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: FyneColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (!_seedRevealed)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_rounded, color: FyneColors.forest, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tocca per rivelare',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: FyneColors.forest),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Copy button with auto-clear
          Center(
            child: TextButton.icon(
              onPressed: _copySeedToClipboard,
              icon: Icon(_seedCopied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
              label: Text(
                _seedCopied ? 'Copiato ($_secondsRemaining s)' : 'Copia negli appunti',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _seedCopied ? FyneColors.forest : FyneColors.inkLight,
              ),
            ),
          ),
          // Countdown visivo prominente
          if (_seedCopied && _secondsRemaining > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _secondsRemaining <= 10
                    ? FyneColors.rust.withOpacity(0.08)
                    : FyneColors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _secondsRemaining <= 10 ? FyneColors.rust : FyneColors.amber,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: _secondsRemaining <= 10 ? FyneColors.rust : FyneColors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-clear tra $_secondsRemaining s',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _secondsRemaining <= 10 ? FyneColors.rust : FyneColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_seedCopied)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Incolla le parole nel tuo password manager ora',
                style: GoogleFonts.inter(fontSize: 11, color: FyneColors.rust, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 24),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: FyneColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Ho Salvato la Chiave',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copySeedToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonic)); // Use _mnemonic (String)
    
    setState(() {
      _seedCopied = true;
      _secondsRemaining = 60; // Reset countdown
    });
    
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seed copiato \u2022 Auto-clear tra 60s',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: FyneColors.forest,
        duration: const Duration(seconds: 4),
      ));
      
    // Countdown visivo ogni secondo
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });

    // Auto-clear clipboard dopo 60 secondi
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 60), () {
      Clipboard.setData(const ClipboardData(text: ''));
      if (mounted) {
        setState(() => _seedCopied = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Appunti cancellati per sicurezza', style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
            backgroundColor: FyneColors.inkLight,
            duration: const Duration(seconds: 3),
          ));
      }
    });
  }

  // ─────────────────────────────────────────────
  // Step 2: Backup Confirmation
  // ─────────────────────────────────────────────

  Widget _buildBackupConfirmStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Conferma\nil Backup',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prima di procedere, assicurati di aver salvato le 12 parole in un posto sicuro.',
            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
          ),
          const SizedBox(height: 32),

          // Info cards
          _buildInfoCard(
            icon: Icons.edit_note_rounded,
            title: 'Scrivile su carta',
            subtitle: 'Carta e penna sono il metodo più sicuro.',
            color: FyneColors.forest,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.cloud_off_rounded,
            title: 'Mai online',
            subtitle: 'Non salvarle in email, chat, o cloud.',
            color: FyneColors.amber,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.lock_outline_rounded,
            title: 'Posto sicuro',
            subtitle: 'Conservale dove solo tu puoi trovarle.',
            color: FyneColors.forestDark,
          ),
          const SizedBox(height: 32),

          // Warning box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FyneColors.rust.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FyneColors.rust.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_rounded, color: FyneColors.rust, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Senza questa chiave, NON potrai recuperare i tuoi dati. Mai.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FyneColors.rust,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3 Checkbox di conferma
          _buildConfirmCheckbox(
            value: _confirmedPhysicalBackup,
            onChanged: (v) => setState(() => _confirmedPhysicalBackup = v),
            title: 'Ho salvato le 12 parole in un posto sicuro',
            subtitle: 'Cartaceo o password manager, NON screenshot',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 12),
          _buildConfirmCheckbox(
            value: _confirmedUnderstanding,
            onChanged: (v) => setState(() => _confirmedUnderstanding = v),
            title: 'Comprendo che senza queste parole perder\u00f2 TUTTI i miei dati',
            subtitle: 'Nemmeno Fyne pu\u00f2 recuperarli (zero-knowledge)',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 12),
          _buildConfirmCheckbox(
            value: _confirmedResponsibility,
            onChanged: (v) => setState(() => _confirmedResponsibility = v),
            title: 'Mi assumo la piena responsabilit\u00e0 della custodia',
            subtitle: 'Sono l\'unico custode di queste parole',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 24),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _allBackupConfirmed ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: FyneColors.forest,
                foregroundColor: Colors.white,
                disabledBackgroundColor: FyneColors.paperDark,
                disabledForegroundColor: FyneColors.inkLighter,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _allBackupConfirmed ? 'Continua alla Verifica \u2713' : 'Conferma tutti i punti per proseguire',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmCheckbox({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? FyneColors.forest.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? FyneColors.forest : FyneColors.paperDark,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? FyneColors.forest : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? FyneColors.forest : FyneColors.inkLighter,
                  width: 2,
                ),
              ),
              child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: FyneColors.rust, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FyneColors.paperDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Step 3: Seed Verification
  // ─────────────────────────────────────────────

  bool get _allVerified => 
    _verificationStatus.length == 3 && 
    _verificationStatus.values.every((v) => v == true);

  Widget _buildSeedVerifyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Verifica la\nTua Chiave',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Per assicurarci che tu abbia salvato correttamente il seed, inserisci le parole richieste.',
            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
          ),
          
          // Show which words are requested
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FyneColors.forest.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: FyneColors.forest, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verifica parole #${_wordsToVerify.map((i) => i + 1).join(', #')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: FyneColors.forest,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Verification fields
          ..._wordsToVerify.map((index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parola #${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _verifyControllers[index],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Inserisci la parola...',
                      suffixIcon: _verificationStatus[index] == true
                        ? const Icon(Icons.check_circle, color: FyneColors.forest)
                        : _verificationStatus[index] == false
                          ? const Icon(Icons.error, color: FyneColors.rust)
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _verificationStatus[index] == false ? FyneColors.rust : FyneColors.paperDark,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: FyneColors.forest, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (_) => _verifyWord(index),
                  ),
                ],
              ),
            );
          }).toList(),

          if (!_allVerified && _verificationStatus.containsValue(false)) ...[
             const SizedBox(height: 12),
             Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FyneColors.rust.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: FyneColors.rust),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Una o più parole non sono corrette.',
                      style: TextStyle(color: FyneColors.rust),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          
          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _allVerified ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: FyneColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                disabledBackgroundColor: FyneColors.paperDark,
                disabledForegroundColor: FyneColors.inkLighter,
              ),
              child: Text(
                'Verifica Completata',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ─────────────────────────────────────────────
  // Step 4: Biometric Setup
  // ─────────────────────────────────────────────

  Widget _buildBiometricStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Sblocco\nRapido',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Abilita lo sblocco biometrico per accedere rapidamente al tuo vault.',
            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
          ),
          const SizedBox(height: 40),

          // Biometric icon
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _biometricEnabled
                    ? FyneColors.forest.withOpacity(0.1)
                    : FyneColors.paperDark.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 56,
                color: _biometricEnabled ? FyneColors.forest : FyneColors.inkLighter,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Toggle
          if (_biometricAvailable) ...[
            InkWell(
              onTap: () => setState(() => _biometricEnabled = !_biometricEnabled),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _biometricEnabled ? FyneColors.forest : FyneColors.paperDark,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      color: _biometricEnabled ? FyneColors.forest : FyneColors.inkLight,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Face ID / Touch ID',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Sblocca il vault con la biometria',
                            style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _biometricEnabled,
                      onChanged: (v) => setState(() => _biometricEnabled = v),
                      activeColor: FyneColors.forest,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FyneColors.paperDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Il tuo dispositivo non supporta la biometria. Potrai configurarla in seguito.',
                      style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Puoi sempre modificare questa impostazione nelle Impostazioni.',
            style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)er),
          ),
          const SizedBox(height: 40),

          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _completeSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: FyneColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Completa Configurazione',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (!_biometricEnabled)
            Center(
              child: TextButton(
                onPressed: _isProcessing ? null : _completeSetup,
                child: Text(
                  'Salta per ora',
                  style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
