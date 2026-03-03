import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/fyne_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/seed_service.dart';
import 'recovery_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colori dark theme (alias locali per leggibilità)
// ─────────────────────────────────────────────────────────────────────────────
const _kInk = FyneColors.ink;           // #1A1A1A — sfondo principale
const _kSurface = Color(0xFF2A2A2A);    // #2A2A2A — superficie card
const _kForest = FyneColors.forest;     // #4A6741 — bottoni primari
const _kPaper = FyneColors.paper;       // #F5F5F0 — testo principale

/// Wizard obbligatorio al primo accesso.
///
/// 3 step:
///   1. Spiegazione Zero-Knowledge  → l'utente comprende il modello di sicurezza
///   2. Visualizzazione Seed Phrase → 24 parole BIP39 (256 bit)
///   3. Verifica + Biometria        → conferma che il seed sia stato salvato
///
/// Al completamento chiama [AuthNotifier.completeWizardSetup], che:
///   a) deriva la passphrase dal mnemonic (Argon2id)
///   b) inizializza il Vault tramite CryptoService
///   c) salva hash e passphrase in flutter_secure_storage
///   d) aggiorna lo stato in AuthStatus.authenticated
class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  final _pageController = PageController();
  final _seedService = SeedService();

  // Seed generato una sola volta in initState — mai ricreato
  late final String _mnemonic;
  late final List<String> _words; // 24 parole

  int _currentStep = 0; // 0=ZK, 1=Seed, 2=Verifica

  // ── Step 1 ─────────────────────────────────────────────────────────────────
  bool _seedRevealed = false;
  bool _seedCopied = false;
  int _secondsRemaining = 60;
  Timer? _clipboardClearTimer;
  Timer? _countdownTimer;

  // ── Step 2 ─────────────────────────────────────────────────────────────────
  List<int> _wordsToVerify = []; // 3 indici random (0-based, ordinati)
  final Map<int, TextEditingController> _verifyControllers = {};
  final Map<int, bool> _verificationStatus = {};

  // ── Biometria ──────────────────────────────────────────────────────────────
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // ── Stato loading ──────────────────────────────────────────────────────────
  bool _isProcessing = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Genera il seed UNA SOLA VOLTA — 24 parole, 256 bit di entropia BIP39
    _mnemonic = _seedService.generateMnemonic();
    _words = _seedService.mnemonicToWords(_mnemonic);

    // Selezione di 3 indici casuali univoci per la verifica
    _wordsToVerify = _seedService.getRandomVerificationIndices(
      count: 3,
      totalWords: 24,
    );
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
    for (final c in _verifyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: verifica disponibilità biometrica
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _checkBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      final available = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = available && isDeviceSupported);
      }
    } catch (_) {
      // Biometria non disponibile sul dispositivo — ignorato silenziosamente
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigazione tra step
  // ─────────────────────────────────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: verifica parola singola (Step 2)
  // ─────────────────────────────────────────────────────────────────────────

  void _verifyWord(int index) {
    final input = _verifyControllers[index]!.text.trim().toLowerCase();
    final correct = _words[index].toLowerCase();
    setState(() => _verificationStatus[index] = input == correct);

    if (_verificationStatus[index] == true) {
      HapticFeedback.lightImpact(); // Corretta → feedback leggero
    } else {
      HapticFeedback.mediumImpact(); // Errata → feedback medio
    }
  }

  bool get _allVerified =>
      _verificationStatus.length == 3 &&
      _verificationStatus.values.every((v) => v == true);

  // ─────────────────────────────────────────────────────────────────────────
  // Completamento wizard
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _completeSetup() async {
    setState(() => _isProcessing = true);

    // IMPORTANTE: cattura il notifier PRIMA di qualsiasi await.
    // Dopo await il BuildContext potrebbe non essere più valido e
    // ref.read() su un'istanza invalidata può causare errori Riverpod.
    final notifier = ref.read(authProvider.notifier);

    try {
      await notifier.completeWizardSetup(
        _mnemonic,
        biometricEnabled: _biometricEnabled,
      );
      HapticFeedback.heavyImpact(); // Successo → feedback intenso
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Errore configurazione: ${e.toString()}',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: FyneColors.rust,
              duration: const Duration(seconds: 5),
            ),
          );
      }
    } finally {
      // mounted check obbligatorio dopo await
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Clipboard: copia e auto-cancellazione dopo 60s (sicurezza)
  // ─────────────────────────────────────────────────────────────────────────

  void _copySeedToClipboard() {
    Clipboard.setData(ClipboardData(text: _mnemonic));
    setState(() {
      _seedCopied = true;
      _secondsRemaining = 60;
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
                'Seed copiato • Auto-cancellazione tra 60s',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: _kForest,
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
      if (_secondsRemaining <= 0) timer.cancel();
    });

    // Auto-cancellazione clipboard dopo 60 secondi
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
                Text(
                  'Appunti cancellati per sicurezza',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: FyneColors.inkLight,
            duration: const Duration(seconds: 3),
          ));
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build principale
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kInk,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Configurazione Vault',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: _kPaper,
          ),
        ),
        // Link di recupero per utenti che reinstallano l'app
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecoveryScreen()),
            ),
            icon: const Icon(Icons.key_rounded, color: FyneColors.amber, size: 18),
            label: Text(
              'Recupera',
              style: GoogleFonts.inter(
                color: FyneColors.amber,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildZeroKnowledgeStep(),
                  _buildSeedDisplayStep(),
                  _buildSeedVerifyStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Progress bar (3 segmenti)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: _kPaper.withValues(alpha:0.5),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              if (_currentStep == 0) const SizedBox(width: 40),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} di 3',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kPaper.withValues(alpha:0.5),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _currentStep ? _kForest : _kSurface,
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

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0: Spiegazione Zero-Knowledge
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildZeroKnowledgeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona hero
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _kForest.withValues(alpha:0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 44,
                color: _kForest,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Titolo
          Text(
            'Il tuo Vault\nZero-Knowledge',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _kPaper,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Fyne non conosce le tue chiavi. Nessun server. Nessuna terza parte. '
            'Solo tu controlli i tuoi dati finanziari.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: _kPaper.withValues(alpha:0.65),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Card feature 1
          _buildZkFeatureCard(
            icon: Icons.key_rounded,
            iconColor: _kForest,
            title: 'Solo tu possiedi le chiavi',
            subtitle:
                'Le chiavi crittografiche non lasciano mai il tuo dispositivo. '
                'Nessun dipendente Fyne può accedere ai tuoi dati.',
          ),
          const SizedBox(height: 12),

          // Card feature 2
          _buildZkFeatureCard(
            icon: Icons.lock_rounded,
            iconColor: FyneColors.amber,
            title: 'AES-256 + Argon2id locale',
            subtitle:
                'I dati vengono cifrati sul dispositivo prima di qualsiasi '
                'sincronizzazione. Il cloud vede solo dati inaccessibili.',
          ),
          const SizedBox(height: 12),

          // Card feature 3
          _buildZkFeatureCard(
            icon: Icons.grain_rounded,
            iconColor: FyneColors.forestLight,
            title: 'Seed Phrase = backup totale',
            subtitle:
                'Le 24 parole che stai per generare sono l\'unico modo per '
                'recuperare il vault su un nuovo dispositivo.',
          ),
          const SizedBox(height: 40),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Genera il mio Seed',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card feature per lo step Zero-Knowledge.
  Widget _buildZkFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha:0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPaper,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _kPaper.withValues(alpha:0.55),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Visualizzazione Seed Phrase (24 parole)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSeedDisplayStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner recupero per utenti che reinstallano
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FyneColors.amber.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FyneColors.amber.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded,
                    color: FyneColors.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RecoveryScreen()),
                    ),
                    child: Text(
                      'Hai già un account? Recupera con le tue 24 parole →',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: FyneColors.amber,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: FyneColors.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Titolo
          Text(
            'La Tua\nSeed Phrase',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _kPaper,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Queste 24 parole sono l\'unico modo per recuperare i tuoi dati. '
            'Salvale su carta o in un password manager offline.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _kPaper.withValues(alpha:0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Warning sicurezza
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FyneColors.rust.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FyneColors.rust.withValues(alpha:0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: FyneColors.rust, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Non condividere con nessuno. Chi le possiede controlla il tuo vault.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: FyneColors.rust, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid 24 parole (3 colonne × 8 righe)
          GestureDetector(
            onTap: () {
              setState(() => _seedRevealed = !_seedRevealed);
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withValues(alpha:0.06)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Griglia parole
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: 24,
                    itemBuilder: (context, i) {
                      return Container(
                        decoration: BoxDecoration(
                          color: _kForest.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _kForest.withValues(alpha:0.18)),
                        ),
                        alignment: Alignment.center,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${i + 1}. ',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: FyneColors.inkLighter,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: _seedRevealed
                                    ? _words[i]
                                    : '••••',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: FyneColors.forestLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Overlay "tocca per rivelare"
                  if (!_seedRevealed)
                    Container(
                      decoration: BoxDecoration(
                        color: _kSurface.withValues(alpha:0.90),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_rounded,
                              color: _kForest, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tocca per rivelare',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: _kForest),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottone copia + countdown
          Center(
            child: TextButton.icon(
              onPressed: _copySeedToClipboard,
              icon: Icon(
                _seedCopied
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(
                _seedCopied
                    ? 'Copiato ($_secondsRemaining s)'
                    : 'Copia negli appunti',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor:
                    _seedCopied ? _kForest : _kPaper.withValues(alpha:0.5),
              ),
            ),
          ),

          // Countdown visivo
          if (_seedCopied && _secondsRemaining > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (_secondsRemaining <= 10
                          ? FyneColors.rust
                          : FyneColors.amber)
                      .withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _secondsRemaining <= 10
                        ? FyneColors.rust
                        : FyneColors.amber,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _secondsRemaining <= 10
                          ? FyneColors.rust
                          : FyneColors.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-cancellazione tra $_secondsRemaining s',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _secondsRemaining <= 10
                            ? FyneColors.rust
                            : FyneColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Ho Salvato il Seed',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Verifica Seed + Biometria
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSeedVerifyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo
          Text(
            'Verifica il\nTuo Seed',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _kPaper,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Inserisci le parole richieste per confermare di aver salvato correttamente la seed phrase.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _kPaper.withValues(alpha:0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Info: quali parole verificare
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kForest.withValues(alpha:0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _kForest, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verifica parole #${_wordsToVerify.map((i) => i + 1).join(', #')}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _kForest,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Campi di verifica
          ..._wordsToVerify.map((index) {
            final status = _verificationStatus[index];
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
                      color: _kPaper.withValues(alpha:0.55),
                      letterSpacing: 0.8,
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
                      color: _kPaper,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Inserisci la parola...',
                      hintStyle: GoogleFonts.inter(
                          color: _kPaper.withValues(alpha:0.3), fontSize: 14),
                      filled: true,
                      fillColor: _kSurface,
                      suffixIcon: status == true
                          ? const Icon(Icons.check_circle,
                              color: FyneColors.forestLight)
                          : status == false
                              ? const Icon(Icons.error,
                                  color: FyneColors.rust)
                              : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: status == false
                              ? FyneColors.rust
                              : Colors.white.withValues(alpha:0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: _kForest, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    onChanged: (_) => _verifyWord(index),
                  ),
                ],
              ),
            );
          }),

          // Messaggio errore se almeno una parola è sbagliata
          if (!_allVerified && _verificationStatus.containsValue(false)) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: FyneColors.rust.withValues(alpha:0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: FyneColors.rust, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Una o più parole non sono corrette. Controlla il seed.',
                      style: GoogleFonts.inter(
                          color: FyneColors.rust, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),

          // ── Sezione biometria (opzionale) ───────────────────────────────
          if (_biometricAvailable) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _biometricEnabled
                      ? _kForest
                      : Colors.white.withValues(alpha:0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    color: _biometricEnabled
                        ? _kForest
                        : _kPaper.withValues(alpha:0.4),
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Face ID / Touch ID',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPaper,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sblocca rapidamente il vault con la biometria',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _kPaper.withValues(alpha:0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _biometricEnabled,
                    onChanged: (v) =>
                        setState(() => _biometricEnabled = v),
                    activeColor: _kForest,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puoi modificare questa impostazione in qualsiasi momento nelle Impostazioni.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _kPaper.withValues(alpha:0.35),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 16),
          ],

          // ── Bottone completamento ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_allVerified && !_isProcessing) ? _completeSetup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kForest,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kSurface,
                disabledForegroundColor: _kPaper.withValues(alpha:0.3),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _allVerified
                          ? 'Completa Configurazione ✓'
                          : 'Inserisci le parole per continuare',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
