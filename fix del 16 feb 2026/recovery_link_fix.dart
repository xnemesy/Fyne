// FIX RECOVERY LINK VISIBILITÀ
// In master_key_wizard.dart - Aggiungi all'inizio del wizard

class MasterKeyWizard extends StatefulWidget {
  // ...
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================
      // NUOVO: AppBar con link recovery
      // ========================================
      appBar: AppBar(
        title: Text('Configurazione Vault'),
        actions: [
          // Link recovery visibile sempre
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecoveryScreen(),
                ),
              );
            },
            icon: Icon(Icons.key, color: FyneColors.forest),
            label: Text(
              'Recupera',
              style: TextStyle(color: FyneColors.forest),
            ),
          ),
        ],
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            // ========================================
            // ALTERNATIVA: Banner in Step 1 con link recovery
            // ========================================
            if (_currentStep == 0)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FyneColors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FyneColors.amber),
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
                            'Hai già un account?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: FyneColors.amber,
                            ),
                          ),
                          SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecoveryScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Recupera con le tue 12 parole →',
                              style: TextStyle(
                                color: FyneColors.forest,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // ... resto del wizard ...
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: _buildSteps(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// BONUS: Aggiungi anche nella schermata login (se esiste)
// ========================================
// In login_screen.dart

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ... logo, form, ecc ...
            
            SizedBox(height: 32),
            
            // Link recovery prominente
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecoveryScreen(),
                  ),
                );
              },
              icon: Icon(Icons.key),
              label: Text('Recupera Account con Seed Phrase'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              'Hai perso il dispositivo? Usa le 12 parole salvate.',
              style: TextStyle(
                fontSize: 12,
                color: FyneColors.inkLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
