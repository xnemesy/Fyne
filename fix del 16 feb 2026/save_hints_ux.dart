// MIGLIORIA: Hint "Dove Salvare il Seed"
// In master_key_wizard.dart - Step 1

class _SeedDisplayStepState extends State<SeedDisplayStep> {
  // ... existing code ...
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Text(
          'La Tua Chiave di Recupero',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 8),
        Text(
          'Salva queste 12 parole in modo sicuro. Sono l\'UNICA via per recuperare i tuoi dati.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 24),
        
        // ========================================
        // NUOVO: Card con suggerimenti di salvataggio
        // ========================================
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FyneColors.forest.withOpacity(0.1),
                FyneColors.moss.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FyneColors.forest.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: FyneColors.forest, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dove salvare in sicurezza?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: FyneColors.forest,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Opzione 1: Password Manager
              _buildSaveOption(
                icon: Icons.vpn_key,
                title: 'Password Manager',
                subtitle: '1Password, Bitwarden, LastPass',
                recommended: true,
              ),
              
              SizedBox(height: 8),
              
              // Opzione 2: Cartaceo
              _buildSaveOption(
                icon: Icons.description,
                title: 'Carta fisica',
                subtitle: 'Scrivi a mano e conserva in cassaforte',
                recommended: true,
              ),
              
              SizedBox(height: 8),
              
              // Opzione 3: Note criptate
              _buildSaveOption(
                icon: Icons.note,
                title: 'Note criptate',
                subtitle: 'Apple Notes (locked), Google Keep',
                recommended: false,
              ),
              
              Divider(height: 24),
              
              // Warning su cosa NON fare
              Row(
                children: [
                  Icon(Icons.warning_amber, color: FyneColors.rust, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NON salvare in: Screenshot, email, messaggi, cloud non cifrato',
                      style: TextStyle(
                        fontSize: 11,
                        color: FyneColors.rust,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // ... seed words grid ...
        
        // ... copy button, countdown, etc ...
      ],
    );
  }
  
  Widget _buildSaveOption({
    required IconData icon,
    required String title,
    required String subtitle,
    bool recommended = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: recommended 
              ? FyneColors.forest.withOpacity(0.2)
              : FyneColors.inkLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: recommended ? FyneColors.forest : FyneColors.inkLight,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (recommended) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: FyneColors.forest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '✓',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: FyneColors.inkLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
