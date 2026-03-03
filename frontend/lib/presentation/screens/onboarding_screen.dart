import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/fyne_theme.dart';

/// Provider per tracciare se l'onboarding è stato completato
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Benvenuto in Fyne',
      description: 'Il tuo vault finanziario personale, completamente cifrato e privato. I tuoi dati restano solo tuoi.',
      icon: Icons.shield_outlined,
      color: FyneColors.forest,
      illustration: 'shield',
    ),
    OnboardingPage(
      title: 'Zero-Knowledge Banking',
      description: 'Tutto è cifrato end-to-end. Nemmeno noi possiamo vedere i tuoi dati finanziari. Solo tu hai le chiavi.',
      icon: Icons.lock_outlined,
      color: FyneColors.amber,
      illustration: 'lock',
    ),
    OnboardingPage(
      title: 'Traccia le tue Finanze',
      description: 'Registra transazioni, gestisci conti multipli e monitora il tuo cash flow in tempo reale.',
      icon: Icons.account_balance_wallet_outlined,
      color: FyneColors.moss,
      illustration: 'wallet',
    ),
    OnboardingPage(
      title: 'Backup Sicuro',
      description: 'Esporta i tuoi dati in un file .fyne cifrato. Ripristinali quando vuoi, su qualsiasi dispositivo.',
      icon: Icons.backup_outlined,
      color: FyneColors.gold,
      illustration: 'backup',
    ),
    OnboardingPage(
      title: 'Pronto a Iniziare?',
      description: 'Crea il tuo account e inizia a prendere il controllo delle tue finanze in modo sicuro.',
      icon: Icons.rocket_launch_outlined,
      color: FyneColors.forest,
      illustration: 'rocket',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      // Invalidate the provider so AuthWrapper re-evaluates routing
      ref.invalidate(onboardingCompletedProvider);
      // AuthWrapper will now show the appropriate screen based on auth state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Salta'),
                ),
              ),

            // PageView con le pagine dell'onboarding
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicatori e pulsanti
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pulsanti navigazione
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      if (_currentPage > 0)
                        TextButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Indietro'),
                        )
                      else
                        const SizedBox(width: 100),

                      // Next/Complete button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage < _pages.length - 1
                                  ? 'Avanti'
                                  : 'Inizia',
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage < _pages.length - 1
                                  ? Icons.arrow_forward
                                  : Icons.check,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: page.color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Features (solo per alcune pagine)
          if (page.features != null) ...[
            const SizedBox(height: 32),
            ...page.features!.map((feature) => _buildFeatureItem(feature)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: FyneColors.forest, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? FyneColors.forest : FyneColors.paperDark,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Modello per una pagina dell'onboarding
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String illustration;
  final List<String>? features;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.illustration,
    this.features,
  });
}

/// Widget per mostrare tutorial contestuale nelle schermate principali
class InAppTutorialOverlay extends StatefulWidget {
  final Widget child;
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const InAppTutorialOverlay({
    Key? key,
    required this.child,
    required this.steps,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<InAppTutorialOverlay> createState() => _InAppTutorialOverlayState();
}

class _InAppTutorialOverlayState extends State<InAppTutorialOverlay> {
  int _currentStep = 0;
  bool _showTutorial = true;

  @override
  Widget build(BuildContext context) {
    if (!_showTutorial || _currentStep >= widget.steps.length) {
      return widget.child;
    }

    final step = widget.steps[_currentStep];

    return Stack(
      children: [
        widget.child,
        
        // Overlay scuro
        Container(
          color: FyneColors.blind,
        ),

        // Tutorial bubble
        Positioned(
          top: step.position.dy,
          left: step.position.dx,
          child: _buildTutorialBubble(step),
        ),
      ],
    );
  }

  Widget _buildTutorialBubble(TutorialStep step) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(step.icon, color: FyneColors.forest),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentStep + 1}/${widget.steps.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
              Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () {
                        setState(() => _currentStep--);
                      },
                      child: const Text('Indietro'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep < widget.steps.length - 1) {
                        setState(() => _currentStep++);
                      } else {
                        setState(() => _showTutorial = false);
                        widget.onComplete();
                      }
                    },
                    child: Text(
                      _currentStep < widget.steps.length - 1
                          ? 'Avanti'
                          : 'Fine',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Singolo step del tutorial contestuale
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Offset position;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.position,
  });
}
