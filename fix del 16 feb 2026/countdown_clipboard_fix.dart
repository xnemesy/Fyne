// FIX COUNTDOWN CLIPBOARD
// In master_key_wizard.dart - Step 1 (SeedDisplayStep)

class _SeedDisplayStepState extends State<SeedDisplayStep> {
  Timer? _clipboardClearTimer;
  Timer? _countdownTimer;  // ← NUOVO: Timer per UI countdown
  bool _seedCopied = false;
  int _secondsRemaining = 60;  // ← NUOVO: Secondi rimanenti
  
  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    _countdownTimer?.cancel();  // ← IMPORTANTE: Cleanup
    super.dispose();
  }
  
  void _copySeedToClipboard() {
    final seedText = widget.seedWords.join(' ');
    
    // Copia negli appunti
    Clipboard.setData(ClipboardData(text: seedText));
    
    setState(() {
      _seedCopied = true;
      _secondsRemaining = 60;  // Reset countdown
    });
    
    // Snackbar iniziale
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '✓ Seed copiato negli appunti\n'
                '⏱️ Verrà cancellato automaticamente tra 60 secondi',
              ),
            ),
          ],
        ),
        backgroundColor: FyneColors.forest,
        duration: Duration(seconds: 4),
      ),
    );
    
    // ========================================
    // NUOVO: Countdown visivo che decrementa ogni secondo
    // ========================================
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _secondsRemaining--;
      });
      
      // Stop a 0
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
    
    // ========================================
    // Timer finale per clear clipboard (invariato)
    // ========================================
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(Duration(seconds: 60), () {
      Clipboard.setData(ClipboardData(text: ''));
      
      if (mounted) {
        setState(() => _seedCopied = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.white),
                SizedBox(width: 12),
                Text('🔒 Seed cancellato dagli appunti per sicurezza'),
              ],
            ),
            backgroundColor: FyneColors.inkLight,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... seed display grid ...
        
        SizedBox(height: 24),
        
        // ========================================
        // NUOVO: Countdown visivo prominente
        // ========================================
        if (_seedCopied && _secondsRemaining > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _secondsRemaining <= 10 
                ? FyneColors.rust.withOpacity(0.1)  // Rosso ultimi 10s
                : FyneColors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _secondsRemaining <= 10 
                  ? FyneColors.rust 
                  : FyneColors.amber,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  color: _secondsRemaining <= 10 
                    ? FyneColors.rust 
                    : FyneColors.amber,
                ),
                SizedBox(width: 8),
                Text(
                  'Auto-clear tra $_secondsRemaining secondi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _secondsRemaining <= 10 
                      ? FyneColors.rust 
                      : FyneColors.amber,
                  ),
                ),
              ],
            ),
          ),
        
        SizedBox(height: 16),
        
        // Copy button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _copySeedToClipboard,
              icon: Icon(_seedCopied ? Icons.check : Icons.copy),
              label: Text(
                _seedCopied 
                  ? 'Copiato ($_secondsRemaining s)'  // ← Mostra countdown
                  : 'Copia negli Appunti',
              ),
              style: TextButton.styleFrom(
                foregroundColor: _seedCopied 
                  ? FyneColors.forest 
                  : FyneColors.inkLight,
              ),
            ),
          ],
        ),
        
        if (_seedCopied)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '⚠️ Incolla il seed nel tuo password manager SUBITO',
              style: TextStyle(
                color: FyneColors.rust,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
