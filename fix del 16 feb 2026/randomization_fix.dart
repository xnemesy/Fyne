// FIX RANDOMIZZAZIONE VERIFICA SEED
// In master_key_wizard.dart - Step 3 (SeedVerificationStep)

class _SeedVerificationStepState extends State<SeedVerificationStep> {
  late List<int> wordsToVerify;
  final Map<int, TextEditingController> controllers = {};
  final Map<int, bool> verificationStatus = {};
  
  @override
  void initState() {
    super.initState();
    
    // ========================================
    // FIX: Genera 3 indici UNICI senza duplicati
    // ========================================
    wordsToVerify = _generateUniqueRandomIndices(3, 12);
    
    for (final index in wordsToVerify) {
      controllers[index] = TextEditingController();
    }
  }
  
  /// Genera [count] indici random UNICI tra 0 e [max-1]
  List<int> _generateUniqueRandomIndices(int count, int max) {
    final random = Random();
    final indices = <int>{};  // Set per garantire unicità
    
    // Genera finché non hai [count] indici unici
    while (indices.length < count) {
      indices.add(random.nextInt(max));
    }
    
    // Converti a lista e ordina per UX migliore
    return indices.toList()..sort();
  }
  
  // ========================================
  // BONUS: Aggiungi validazione case-insensitive
  // ========================================
  void _verifyWord(int index) {
    final input = controllers[index]!.text.trim().toLowerCase();
    final correct = widget.originalSeed[index].toLowerCase();
    
    setState(() {
      verificationStatus[index] = input == correct;
    });
    
    // Feedback aptico
    if (verificationStatus[index] == true) {
      HapticFeedback.lightImpact();
    } else if (verificationStatus[index] == false) {
      HapticFeedback.mediumImpact();
    }
  }
  
  bool get _allVerified => 
    verificationStatus.length == 3 && 
    verificationStatus.values.every((v) => v == true);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verifica il Tuo Seed',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 8),
        Text(
          'Per assicurarci che tu abbia salvato correttamente il seed, '
          'inserisci le parole richieste.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        
        // ========================================
        // NUOVO: Mostra quali parole vengono richieste
        // ========================================
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FyneColors.forest.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: FyneColors.forest, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifica parole #${wordsToVerify.map((i) => i + 1).join(', #')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: FyneColors.forest,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Input fields
        ...wordsToVerify.map((index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parola #${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: FyneColors.forest,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    hintText: 'Inserisci la parola...',
                    suffixIcon: verificationStatus[index] == true
                      ? Icon(Icons.check_circle, color: FyneColors.forest)
                      : verificationStatus[index] == false
                        ? Icon(Icons.error, color: FyneColors.rust)
                        : null,
                  ),
                  onChanged: (_) => _verifyWord(index),
                  autocorrect: false,  // ← IMPORTANTE: Disabilita autocorrect
                  enableSuggestions: false,
                ),
              ],
            ),
          );
        }).toList(),
        
        if (!_allVerified && verificationStatus.containsValue(false))
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FyneColors.rust.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: FyneColors.rust),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Una o più parole non sono corrette. Ricontrolla il tuo backup.',
                    style: TextStyle(color: FyneColors.rust),
                  ),
                ),
              ],
            ),
          ),
        
        Spacer(),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _allVerified ? () => widget.onNext() : null,
            child: Text('Verifica Completata'),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

// ========================================
// BONUS: Unit test per verifica randomizzazione
// ========================================
void main() {
  test('should generate unique random indices', () {
    final indices = _generateUniqueRandomIndices(3, 12);
    
    // Check: esattamente 3 elementi
    expect(indices.length, 3);
    
    // Check: tutti diversi (no duplicati)
    expect(indices.toSet().length, 3);
    
    // Check: tutti tra 0 e 11
    for (final index in indices) {
      expect(index, greaterThanOrEqualTo(0));
      expect(index, lessThan(12));
    }
    
    // Check: ordinati crescente per UX
    expect(indices, isSorted);
  });
}
