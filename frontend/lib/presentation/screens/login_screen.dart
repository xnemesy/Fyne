import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/auth_provider.dart';
import 'recovery_screen.dart';

/// Schermata di login minimale post-onboarding.
/// Supporta login anonimo (Opzione A) + Email + Google.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Email/Password controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailForm = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAnonymousStart() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // Sign in anonymously with Firebase, then auto-generate keys
      await ref.read(authProvider.notifier).signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Errore durante l\'avvio. Riprova.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Accesso Google fallito. Riprova.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Inserisci email e password.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authProvider.notifier).signInWithEmail(
        email, password, isSignUp: _isSignUp,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _isSignUp
          ? 'Registrazione fallita. L\'email potrebbe essere già in uso.'
          : 'Credenziali errate. Riprova.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show loader during key initialization
    if (authState.status == AuthStatus.initializingKeys ||
        authState.status == AuthStatus.signingIn) {
      return Scaffold(
        backgroundColor: FyneColors.paper,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: FyneColors.forest),
              const SizedBox(height: 24),
              Text(
                authState.status == AuthStatus.initializingKeys
                  ? 'Inizializzazione vault sicuro...'
                  : 'Accesso in corso...',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: FyneColors.inkLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FyneColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: FyneColors.forest.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: FyneColors.forest,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'FYNE',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: FyneColors.forest,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Il tuo vault finanziario',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: FyneColors.inkLight,
                ),
              ),
              const SizedBox(height: 48),

              // Error message
              if (_errorMessage != null || authState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FyneColors.softRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: FyneColors.softRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage ?? authState.error ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: FyneColors.softRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Primary CTA: Quick anonymous start
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAnonymousStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FyneColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Text(
                        'Inizia Subito',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'I dati restano solo sul tuo dispositivo',
                style: GoogleFonts.inter(
                  fontSize: 12, color: FyneColors.inkLight,
                ),
              ),
              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: FyneColors.paperDark)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'oppure',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: FyneColors.inkLight,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: FyneColors.paperDark)),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign-in
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: Text('Continua con Google',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FyneColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: FyneColors.paperDark),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email toggle
              TextButton(
                onPressed: () => setState(() => _showEmailForm = !_showEmailForm),
                child: Text(
                  _showEmailForm ? 'Nascondi' : 'Accedi con Email',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: FyneColors.forest,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Email form (collapsible)
              if (_showEmailForm) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.inter(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.inter(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _handleEmailSubmit(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FyneColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_isSignUp ? 'Registrati' : 'Accedi'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                      ? 'Hai già un account? Accedi'
                      : 'Non hai un account? Registrati',
                    style: GoogleFonts.inter(fontSize: 13, color: FyneColors.inkLight),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              // Recovery link
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecoveryScreen()),
                ),
                child: Text(
                  'Hai una chiave di recupero?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: FyneColors.forest,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
