import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

// ─── Costanti palette dark Fyne ──────────────────────────────────────────────

const _kInk     = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2A2A2A);
const _kForest  = Color(0xFF4A6741);
const _kForestLight = Color(0xFF8FA68B);
const _kPaper   = Color(0xFFF5F5F0);
const _kInkLight = Color(0xFF6B6B6B);
const _kRust    = Color(0xFFB85450);

// ─── LockScreen ───────────────────────────────────────────────────────────────

/// Schermata di sblocco vault — dark Fyne theme.
/// Auto-triggera FaceID/TouchID all'apertura se disponibile e abilitata.
/// Fallback: campo passphrase espandibile.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  final _passphraseController = TextEditingController();
  bool _showPassphraseField = false;
  bool _isLoading = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Animazione pulsazione icona biometrica
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-trigger biometrico al mount (UX: sblocco immediato)
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Azioni ─────────────────────────────────────────────────────────────────

  Future<void> _tryBiometric() async {
    // Controlla se biometria abilitata dal wizard
    final biometricEnabled =
        await ref.read(isBiometricEnabledProvider.future);
    final biometricAvailable =
        await ref.read(biometricAvailableProvider.future);

    if (!mounted) return;

    if (biometricEnabled && biometricAvailable) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authProvider.notifier).unlockWithBiometrics();
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Nessuna biometria disponibile → mostra direttamente il campo passphrase
      setState(() => _showPassphraseField = true);
    }
  }

  Future<void> _handlePassphraseUnlock() async {
    final passphrase = _passphraseController.text.trim();
    if (passphrase.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).unlockVault(passphrase);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final biometricAsync = ref.watch(biometricAvailableProvider);
    final biometricEnabledAsync = ref.watch(isBiometricEnabledProvider);

    final showBiometricBtn = biometricAsync.value == true &&
        biometricEnabledAsync.value == true;

    return Scaffold(
      backgroundColor: _kInk,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo + Titolo ─────────────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 48),

              // ── Errore (se presente) ──────────────────────────────────────
              if (authState.error != null) ...[
                _buildErrorBanner(authState.error!),
                const SizedBox(height: 24),
              ],

              // ── Pulsante biometrico ───────────────────────────────────────
              if (showBiometricBtn && !_showPassphraseField) ...[
                _buildBiometricButton(),
                const SizedBox(height: 32),
              ],

              // ── Loading spinner ───────────────────────────────────────────
              if (_isLoading) ...[
                const SizedBox(
                  height: 36,
                  width: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _kForestLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Autenticazione in corso…',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: _kInkLight),
                ),
                const SizedBox(height: 32),
              ],

              // ── Campo passphrase (espandibile) ────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _showPassphraseField
                    ? _buildPassphraseSection()
                    : const SizedBox.shrink(),
              ),

              // ── Link toggle ───────────────────────────────────────────────
              const SizedBox(height: 24),
              if (!_isLoading)
                TextButton(
                  onPressed: () {
                    setState(
                        () => _showPassphraseField = !_showPassphraseField);
                  },
                  child: Text(
                    _showPassphraseField
                        ? 'Usa biometrica'
                        : 'Usa passphrase di recupero',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _kInkLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const Spacer(flex: 3),

              // ── Sign out ──────────────────────────────────────────────────
              TextButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).signOut(),
                child: Text(
                  'ESCI DALL\'ACCOUNT',
                  style: GoogleFonts.inter(
                    color: _kInkLight.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helper privati ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _kForest.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 40,
            color: _kForestLight,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FYNE VAULT',
          style: GoogleFonts.lora(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _kPaper,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Il tuo vault è protetto e bloccato.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _kInkLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _tryBiometric,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kForest.withValues(alpha: 0.1),
            border: Border.all(
              color: _kForest.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.face_outlined,
                size: 48,
                color: _kForestLight,
              ),
              const SizedBox(height: 6),
              Text(
                'SBLOCCA',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: _kForestLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRust.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRust.withValues(alpha: 0.3)),
      ),
      child: Text(
        error,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: _kRust,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPassphraseSection() {
    return Column(
      children: [
        TextField(
          controller: _passphraseController,
          obscureText: true,
          style: GoogleFonts.inter(color: _kPaper, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Passphrase di recupero (24 parole)',
            hintStyle: GoogleFonts.inter(
                color: _kInkLight.withValues(alpha: 0.5), fontSize: 14),
            filled: true,
            fillColor: _kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kForest, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.key_outlined, color: _kInkLight),
          ),
          onSubmitted: (_) => _handlePassphraseUnlock(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePassphraseUnlock,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kForest,
              disabledBackgroundColor: _kSurface,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'SBLOCCA VAULT',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ),
      ],
    );
  }
}
