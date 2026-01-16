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
      title: "Privacy Radicale",
      description: "Architettura Zero-Knowledge. Nemmeno noi possiamo vedere i tuoi dati. La crittografia avviene sul tuo dispositivo.",
      icon: LucideIcons.shieldCheck,
    ),
    OnboardingData(
      title: "Intelligence Locale",
      description: "L'AI corre sul tuo silicio. Analisi delle spese e suggerimenti senza mai inviare i tuoi dati in cloud.",
      icon: LucideIcons.brainCircuit,
    ),
    OnboardingData(
      title: "I tuoi dati, le tue regole",
      description: "Controlla il tuo patrimonio con estetica e precisione. Fyne è la custodia digitale dei tuoi risparmi.",
      icon: LucideIcons.key,
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6741).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 80, color: const Color(0xFF4A6741)),
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
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return Container(
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
        _authButton(
          label: "ACCEDI CON APPLE",
          icon: Icons.apple,
          onPressed: () => ref.read(authProvider.notifier).signInWithApple(),
          backgroundColor: const Color(0xFF1A1A1A),
        ),
        const SizedBox(height: 12),
        _authButton(
          label: "ACCEDI CON GOOGLE",
          icon: LucideIcons.chrome,
          onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
          backgroundColor: Colors.white,
          textColor: const Color(0xFF1A1A1A),
          border: BorderSide(color: const Color(0xFF1A1A1A).withOpacity(0.1)),
        ),
        const SizedBox(height: 12),
        _authButton(
          label: "ACCEDI CON EMAIL",
          icon: LucideIcons.mail,
          onPressed: () => _showEmailAuthSheet(),
          backgroundColor: const Color(0xFF4A6741),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => ref.read(authProvider.notifier).signInAnonymously(),
          child: Text(
            "ACCEDI ANONIMAMENTE",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A6741),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
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
                decoration: InputDecoration(hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(hintText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
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
                  ),
                  child: Text(isSignUp ? "REGISTRATI" : "ACCEDI", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => setModalState(() => isSignUp = !isSignUp),
                child: Text(isSignUp ? "Hai già un account? Accedi" : "Nuovo qui? Crea un account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    Color textColor = Colors.white,
    BorderSide? border,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: border ?? BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isInitializingKeys) {
    return Container(
      color: const Color(0xFFFBFBF9).withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4A6741)),
            const SizedBox(height: 24),
            Text(
              isInitializingKeys ? "GENERAZIONE CHIAVI SICURE..." : "ACCESSO IN CORSO...",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: const Color(0xFF4A6741),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (isInitializingKeys)
              Text(
                "Questo garantisce che i tuoi dati siano solo tuoi.",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF1A1A1A).withOpacity(0.4),
                ),
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
  final IconData icon;

  OnboardingData({required this.title, required this.description, required this.icon});
}
