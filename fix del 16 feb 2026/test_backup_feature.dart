// FEATURE: Test Backup in Settings
// Nuovo screen: test_backup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/fyne_theme.dart';
import '../../services/seed_service.dart';

class TestBackupScreen extends ConsumerStatefulWidget {
  const TestBackupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestBackupScreen> createState() => _TestBackupScreenState();
}

class _TestBackupScreenState extends ConsumerState<TestBackupScreen> {
  final List<TextEditingController> _wordControllers = 
    List.generate(12, (_) => TextEditingController());
  
  bool _isVerifying = false;
  bool? _verificationSuccess;
  String? _errorMessage;
  
  @override
  void dispose() {
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _testBackup() async {
    setState(() {
      _isVerifying = true;
      _verificationSuccess = null;
      _errorMessage = null;
    });
    
    // Assembla mnemonic
    final mnemonic = _wordControllers
      .map((c) => c.text.trim().toLowerCase())
      .join(' ');
    
    // Valida BIP39
    if (!SeedService.validateMnemonic(mnemonic)) {
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _errorMessage = 'Seed non valido. Controlla le parole inserite.';
      });
      return;
    }
    
    // Verifica contro hash salvato
    final isCorrect = await SeedService.verifySeed(mnemonic);
    
    setState(() {
      _isVerifying = false;
      _verificationSuccess = isCorrect;
      _errorMessage = isCorrect 
        ? null 
        : 'Seed non corrisponde al backup. Verifica le parole.';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Testa il Tuo Backup'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con spiegazione
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FyneColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: FyneColors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perché testare il backup?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FyneColors.amber,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Verifica che le parole salvate siano corrette prima di averne bisogno.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Titolo
            Text(
              'Inserisci le Tue 12 Parole',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Inserisci il seed che hai salvato durante il setup.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            SizedBox(height: 24),
            
            // Grid input 12 parole
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return TextField(
                  controller: _wordControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Parola ${index + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(fontSize: 14),
                  textInputAction: index < 11 
                    ? TextInputAction.next 
                    : TextInputAction.done,
                );
              },
            ),
            
            SizedBox(height: 24),
            
            // Result feedback
            if (_verificationSuccess != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _verificationSuccess! 
                    ? FyneColors.forest.withOpacity(0.1)
                    : FyneColors.rust.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _verificationSuccess! 
                      ? FyneColors.forest 
                      : FyneColors.rust,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _verificationSuccess! 
                        ? Icons.check_circle 
                        : Icons.error,
                      color: _verificationSuccess! 
                        ? FyneColors.forest 
                        : FyneColors.rust,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _verificationSuccess! 
                              ? '✓ Backup Corretto!'
                              : '✗ Backup Non Valido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _verificationSuccess! 
                                ? FyneColors.forest 
                                : FyneColors.rust,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            SizedBox(height: 4),
                            Text(
                              _errorMessage!,
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // Test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _testBackup,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isVerifying
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text('Testa Backup'),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Info footer
            Text(
              '💡 Consiglio: Testa il backup ogni 3-6 mesi per assicurarti di ricordare dove l\'hai salvato.',
              style: TextStyle(
                fontSize: 12,
                color: FyneColors.inkLight,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// INTEGRAZIONE: Aggiungi nelle impostazioni
// ========================================
// In settings_screen.dart

ListTile(
  leading: Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: FyneColors.amber.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.verified_user, color: FyneColors.amber),
  ),
  title: Text('Testa il Tuo Backup'),
  subtitle: Text('Verifica che il seed salvato sia corretto'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestBackupScreen(),
      ),
    );
  },
),
