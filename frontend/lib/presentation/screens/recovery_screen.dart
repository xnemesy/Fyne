import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/seed_service.dart';

/// Screen per il ripristino del vault tramite seed phrase.
/// Accessibile dal LoginScreen o dal LockScreen.
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final _seedService = SeedService();
  final List<TextEditingController> _controllers = List.generate(
    12,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(12, (_) => FocusNode());
  
  bool _isRecovering = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _mnemonic => _controllers.map((c) => c.text.trim().toLowerCase()).join(' ');

  Future<void> _recover() async {
    setState(() {
      _error = null;
      _isRecovering = true;
    });

    // Validate
    if (!_seedService.validateMnemonic(_mnemonic)) {
      setState(() {
        _error = 'Le parole inserite non sono valide. Controlla ogni parola.';
        _isRecovering = false;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    try {
      await ref.read(authProvider.notifier).completeWizardSetup(_mnemonic);
      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Errore nel ripristino: ${e.toString()}';
        _isRecovering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FyneColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).colorScheme.onSurface),
        ),
        title: Text(
          'Ripristino Vault',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inserisci la Tua\nChiave di Recupero',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inserisci le 12 parole che hai salvato durante la configurazione iniziale.',
                style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
              ),
              const SizedBox(height: 24),

              // 12-word grid (4×3)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: 12,
                itemBuilder: (context, i) {
                  return TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: i < 11 ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: (_) {
                      if (i < 11) {
                        _focusNodes[i + 1].requestFocus();
                      }
                    },
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      prefixText: '${i + 1}. ',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: FyneColors.paperDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: FyneColors.forest, width: 2),
                      ),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FyneColors.rust.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: FyneColors.rust, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(fontSize: 13, color: FyneColors.rust),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Recover button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRecovering ? null : _recover,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FyneColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isRecovering
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Ripristina Vault',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              Center(
                child: Text(
                  'La chiave non viene inviata a nessun server.',
                  style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
