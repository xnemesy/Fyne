import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Benvenuto in Fyne",
      description: "La gestione finanziaria per chi pretende controllo, non compromessi.",
      icon: LucideIcons.sparkles,
    ),
    OnboardingData(
      title: "Privacy radicale",
      description: "I tuoi dati non lasciano mai il tuo dispositivo. Nemmeno noi possiamo accedervi.",
      microCopy: "Architettura Zero-Knowledge nativa.",
      icon: LucideIcons.shieldCheck,
    ),
    OnboardingData(
      title: "Intelligence locale",
      description: "L'analisi avviene sul tuo dispositivo. Nessun cloud. Nessuna condivisione.",
      microCopy: "AI privata, sempre offline.",
      icon: LucideIcons.brainCircuit,
    ),
    OnboardingData(
      title: "I tuoi dati, le tue regole",
      description: "Inserisci solo ciò che scegli. Nessuna sincronizzazione automatica. Nessuna dipendenza da terze parti.",
      icon: LucideIcons.key,
    ),
    OnboardingData(
      title: "Tutto è pronto",
      description: "Fyne è progettata per funzionare in silenzio, lasciando parlare solo i numeri.",
      icon: LucideIcons.checkCircle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                _buildPageIndicator(),
                const SizedBox(height: 48),
                if (_currentPage == _pages.length - 1)
                  _buildAuthButtons(authState)
                else
                  _buildNextButton(),
              ],
            ),
          ),

          if (authState.status == AuthStatus.signingIn || authState.status == AuthStatus.initializingKeys)
            _buildLoadingOverlay(authState.status == AuthStatus.initializingKeys),
            
          if (authState.error != null)
            _buildErrorHint(authState.error!),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 48, color: const Color(0xFF1A1A1A).withOpacity(0.7)),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF1A1A1A).withOpacity(0.8),
              height: 1.6,
            ),
          ),
          if (page.microCopy != null) ...[
            const SizedBox(height: 16),
            Text(
              page.microCopy!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A).withOpacity(0.3),
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 120), // Spacer for bottom buttons
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? const Color(0xFF4A6741) : const Color(0xFF4A6741).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A6741),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text("CONTINUA", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildAuthButtons(AuthState authState) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showEmailAuthSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text("ACCEDI CON EMAIL", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSocialBtn(LucideIcons.chrome, "Google", () => ref.read(authProvider.notifier).signInWithGoogle()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialBtn(LucideIcons.apple, "Apple", () => ref.read(authProvider.notifier).signInWithApple()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: const Color(0xFF1A1A1A).withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showEmailAuthSheet() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSignUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            left: 32, right: 32, top: 32,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBF9),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isSignUp ? "Crea Account" : "Bentornato", style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email", 
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password", 
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).signInWithEmail(emailController.text, passwordController.text, isSignUp: isSignUp);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6741),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(isSignUp ? "REGISTRATI" : "ACCEDI", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setModalState(() => isSignUp = !isSignUp),
                child: Text(
                  isSignUp ? "Hai già un account? Accedi" : "Nuovo qui? Crea un account",
                  style: GoogleFonts.inter(color: const Color(0xFF1A1A1A).withOpacity(0.5), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isInitializingKeys) {
    return Container(
      color: const Color(0xFFFBFBF9).withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4A6741)),
            const SizedBox(height: 32),
            Text(
              isInitializingKeys ? "GENERAZIONE CHIAVI SICURE..." : "ACCESSO IN CORSO...",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 11,
                color: const Color(0xFF1A1A1A).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                isInitializingKeys 
                  ? "Stiamo creando le tue chiavi crittografiche locali per una privacy totale."
                  : "Stiamo preparando la tua custodia digitale.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1A1A).withOpacity(0.4), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHint(String error) {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
            ),
            IconButton(
              onPressed: () => ref.read(authProvider.notifier).clearError(),
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String? microCopy;
  final IconData icon;
  OnboardingData({required this.title, required this.description, this.microCopy, required this.icon});
}
