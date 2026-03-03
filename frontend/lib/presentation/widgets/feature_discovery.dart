import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/fyne_theme.dart';

/// Widget per mostrare tutorial/hints contestuali alla prima visualizzazione
class FeatureDiscovery extends StatefulWidget {
  final String featureId;
  final Widget child;
  final String title;
  final String description;
  final IconData? icon;
  final bool showOnlyOnce;

  const FeatureDiscovery({
    Key? key,
    required this.featureId,
    required this.child,
    required this.title,
    required this.description,
    this.icon,
    this.showOnlyOnce = true,
  }) : super(key: key);

  @override
  State<FeatureDiscovery> createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _checkIfSeen();
  }

  Future<void> _checkIfSeen() async {
    if (!widget.showOnlyOnce) {
      setState(() => _showHint = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('feature_seen_${widget.featureId}') ?? false;
    
    if (!seen && mounted) {
      setState(() {
        _showHint = true;
      });

      // Mostra dopo un breve delay per dare tempo al widget di renderizzarsi
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _showHint) {
          _showFeatureHint();
        }
      });
    }
  }

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feature_seen_${widget.featureId}', true);
    setState(() {});
  }

  void _showFeatureHint() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FeatureHintDialog(
        title: widget.title,
        description: widget.description,
        icon: widget.icon ?? Icons.lightbulb_outline,
        onDismiss: () {
          _markAsSeen();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _FeatureHintDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onDismiss;

  const _FeatureHintDialog({
    required this.title,
    required this.description,
    required this.icon,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FyneColors.forest.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: FyneColors.forest,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                child: const Text('Ho capito!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Guida interattiva step-by-step per funzioni complesse
class InteractiveTutorial extends StatefulWidget {
  final String tutorialId;
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final Widget child;

  const InteractiveTutorial({
    Key? key,
    required this.tutorialId,
    required this.steps,
    required this.onComplete,
    required this.child,
  }) : super(key: key);

  @override
  State<InteractiveTutorial> createState() => _InteractiveTutorialState();
}

class _InteractiveTutorialState extends State<InteractiveTutorial> {
  int _currentStep = 0;
  bool _tutorialActive = false;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('tutorial_${widget.tutorialId}') ?? false;
    
    if (!completed && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _tutorialActive = true);
        }
      });
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_${widget.tutorialId}', true);
    setState(() => _tutorialActive = false);
    widget.onComplete();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  @override
  Widget build(BuildContext context) {
    if (!_tutorialActive || widget.steps.isEmpty) {
      return widget.child;
    }

    final currentStepData = widget.steps[_currentStep];

    return Stack(
      children: [
        // App content
        widget.child,

        // Dark overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Previeni interazioni
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),

        // Tutorial bubble
        Positioned(
          top: currentStepData.targetPosition?.dy ?? MediaQuery.of(context).size.height * 0.3,
          left: 20,
          right: 20,
          child: _buildTutorialBubble(currentStepData),
        ),

        // Skip button
        Positioned(
          top: 40,
          right: 20,
          child: TextButton.icon(
            onPressed: _skipTutorial,
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text(
              'Salta',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialBubble(TutorialStep step) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentStep
                        ? FyneColors.forest
                        : FyneColors.paperDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon and title
            Row(
              children: [
                if (step.icon != null) ...[
                  Icon(step.icon, color: FyneColors.forest, size: 28),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),

            if (step.actionHint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FyneColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: FyneColors.forest,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.actionHint!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: FyneColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Indietro'),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: _nextStep,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentStep < widget.steps.length - 1
                            ? 'Avanti'
                            : 'Completa',
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep < widget.steps.length - 1
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
    );
  }
}

/// Singolo step di un tutorial interattivo
class TutorialStep {
  final String title;
  final String description;
  final IconData? icon;
  final Offset? targetPosition;
  final String? actionHint;

  TutorialStep({
    required this.title,
    required this.description,
    this.icon,
    this.targetPosition,
    this.actionHint,
  });
}

/// Helper per resettare tutti i tutorial (utile per testing)
class TutorialManager {
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => 
      k.startsWith('tutorial_') || k.startsWith('feature_seen_')
    ).toList();
    
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_$tutorialId');
  }

  static Future<void> resetFeature(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('feature_seen_$featureId');
  }
}
