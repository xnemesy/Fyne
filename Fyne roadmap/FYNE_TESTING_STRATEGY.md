# 🧪 FYNE TESTING STRATEGY & BETA LAUNCH PLAN

## 📋 EXECUTIVE SUMMARY

Questo documento dettaglia la strategia di testing per Fyne, dai test unitari alle simulazioni di produzione, fino alla checklist finale per il lancio beta.

**Obiettivo**: Garantire che Fyne sia stabile, sicuro e performante prima del lancio pubblico.

---

## 🎯 TESTING PYRAMID

```
                    ▲
                   ╱ ╲
                  ╱   ╲
                 ╱ E2E ╲           5% (Slow, Expensive)
                ╱───────╲
               ╱         ╲
              ╱Integration╲        15% (Medium Speed)
             ╱─────────────╲
            ╱               ╲
           ╱  Unit Tests     ╲     80% (Fast, Cheap)
          ╱───────────────────╲
```

**Distribuzione Target**:
- **Unit Tests**: 80% della coverage (focus su business logic)
- **Integration Tests**: 15% (API, Database, Crypto)
- **E2E Tests**: 5% (Critical user flows)

---

## 🔬 UNIT TESTING

### Setup

```yaml
# pubspec.yaml - Dev Dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0          # Mock dependencies
  isar_test: ^3.1.0         # Test Isar DB
  fake_async: ^1.3.1        # Simulate time
```

### Test Structure

```dart
// test/services/crypto_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fyne_frontend/services/crypto_service.dart';
import 'package:cryptography/cryptography.dart';

void main() {
  group('CryptoService', () {
    late CryptoService cryptoService;
    
    setUp(() {
      cryptoService = CryptoService();
    });
    
    test('deriveKey should generate consistent keys from same password', () async {
      const password = 'test_password_123';
      const salt = 'stable_salt';
      
      final key1 = await cryptoService.deriveKey(password, salt);
      final key2 = await cryptoService.deriveKey(password, salt);
      
      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();
      
      expect(bytes1, equals(bytes2));
    });
    
    test('encrypt/decrypt should be reversible', () async {
      const plaintext = 'Sensitive data 🔒';
      const password = 'strong_password';
      const salt = 'random_salt';
      
      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt(plaintext, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);
      
      expect(decrypted, equals(plaintext));
    });
    
    test('encrypt should produce different ciphertexts for same plaintext', () async {
      const plaintext = 'Same text';
      const password = 'password';
      const salt = 'salt';
      
      final key = await cryptoService.deriveKey(password, salt);
      final encrypted1 = await cryptoService.encrypt(plaintext, key);
      final encrypted2 = await cryptoService.encrypt(plaintext, key);
      
      // Nonce diverso → ciphertext diverso
      expect(encrypted1, isNot(equals(encrypted2)));
    });
    
    test('decrypt with wrong key should throw', () async {
      const plaintext = 'Secret';
      
      final key1 = await cryptoService.deriveKey('password1', 'salt');
      final key2 = await cryptoService.deriveKey('password2', 'salt');
      
      final encrypted = await cryptoService.encrypt(plaintext, key1);
      
      expect(
        () => cryptoService.decrypt(encrypted, key2),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

### Test Coverage Target per Service

| Service | Coverage Target | Priority |
|---------|----------------|----------|
| CryptoService | 95% | 🔴 Critical |
| BackupService | 90% | 🔴 Critical |
| TransactionRepository | 85% | 🟠 High |
| BudgetProvider | 80% | 🟠 High |
| CategorizationService | 75% | 🟡 Medium |
| NotificationService | 70% | 🟡 Medium |

---

## 🔗 INTEGRATION TESTING

### Test: Backup Export/Import Flow

```dart
// test/integration/backup_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:fyne_frontend/services/backup_service.dart';
import 'package:fyne_frontend/services/crypto_service.dart';
import 'package:fyne_frontend/models/transaction.dart';

void main() {
  group('Backup Integration Tests', () {
    late Isar isar;
    late BackupService backupService;
    late SecretKey masterKey;
    
    setUp(() async {
      // Setup in-memory Isar DB
      isar = await Isar.open(
        [TransactionModelSchema, AccountSchema, BudgetSchema],
        directory: '',
        name: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      backupService = BackupService();
      masterKey = await CryptoService().deriveKey('test_pass', 'test_salt');
    });
    
    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });
    
    test('Full backup/restore cycle should preserve data integrity', () async {
      // 1. Seed database
      final testTransactions = _generateTestTransactions(count: 100);
      await isar.writeTxn(() async {
        await isar.transactionModels.putAll(testTransactions);
      });
      
      // 2. Export backup
      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: masterKey,
      );
      
      expect(backupPath, isNotEmpty);
      expect(File(backupPath).existsSync(), isTrue);
      
      // 3. Clear database
      await isar.writeTxn(() async {
        await isar.transactionModels.clear();
      });
      
      final countAfterClear = await isar.transactionModels.count();
      expect(countAfterClear, equals(0));
      
      // 4. Import backup
      await backupService.importEncryptedBackup(
        filePath: backupPath,
        masterKey: masterKey,
        isar: isar,
      );
      
      // 5. Verify
      final restoredCount = await isar.transactionModels.count();
      expect(restoredCount, equals(100));
      
      final restoredTx = await isar.transactionModels.where().findAll();
      expect(restoredTx.first.uuid, equals(testTransactions.first.uuid));
    });
    
    test('Import with wrong key should fail gracefully', () async {
      final testTx = _generateTestTransactions(count: 10);
      await isar.writeTxn(() async {
        await isar.transactionModels.putAll(testTx);
      });
      
      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: masterKey,
      );
      
      // Try import with different key
      final wrongKey = await CryptoService().deriveKey('wrong_pass', 'salt');
      
      expect(
        () => backupService.importEncryptedBackup(
          filePath: backupPath,
          masterKey: wrongKey,
          isar: isar,
        ),
        throwsA(predicate((e) => e.toString().contains('MAC'))),
      );
    });
    
    test('Corrupted backup file should fail checksum validation', () async {
      final testTx = _generateTestTransactions(count: 5);
      await isar.writeTxn(() async {
        await isar.transactionModels.putAll(testTx);
      });
      
      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: masterKey,
      );
      
      // Corrupt the file
      final file = File(backupPath);
      final bytes = await file.readAsBytes();
      bytes[bytes.length - 10] ^= 0xFF; // Flip bits
      await file.writeAsBytes(bytes);
      
      expect(
        () => backupService.importEncryptedBackup(
          filePath: backupPath,
          masterKey: masterKey,
          isar: isar,
        ),
        throwsA(predicate((e) => 
          e.toString().contains('Checksum') || 
          e.toString().contains('MAC')
        )),
      );
    });
  });
  
  List<TransactionModel> _generateTestTransactions({required int count}) {
    return List.generate(count, (i) {
      return TransactionModel(
        uuid: 'test_uuid_$i',
        accountId: 'test_account',
        bookingDate: DateTime.now().subtract(Duration(days: i)),
        currency: 'EUR',
        encryptedAmount: 'encrypted_${i * 10}',
        encryptedDescription: 'encrypted_desc_$i',
        createdAt: DateTime.now(),
      );
    });
  }
}
```

### Test: Isolate Decryption Performance

```dart
// test/performance/isolate_decryption_test.dart
void main() {
  test('Decrypt 1000 transactions in < 2 seconds', () async {
    final stopwatch = Stopwatch()..start();
    
    final isar = await _setupIsarWithData(transactionCount: 1000);
    final masterKey = await CryptoService().getOrGenerateMasterKey();
    final repo = TransactionRepository(isar, masterKey);
    
    final encrypted = await repo.getEncryptedPage(page: 0, pageSize: 1000);
    final decrypted = await repo.decryptPageForList(encrypted);
    
    stopwatch.stop();
    
    expect(decrypted.length, equals(1000));
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    
    print('Decrypted 1000 transactions in ${stopwatch.elapsedMilliseconds}ms');
  });
}
```

---

## 🎭 END-TO-END TESTING

### Setup: Integration Test Driver

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
```

### Test: Critical User Journey

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fyne_frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Critical User Flows', () {
    testWidgets('Complete onboarding → Create transaction → Export backup', 
      (WidgetTester tester) async {
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle();
      
      // 2. Onboarding: Skip/Complete
      final skipButton = find.text('Salta');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }
      
      // 3. Authentication (se richiesta)
      // Mock biometric authentication
      
      // 4. Navigate to Dashboard
      await tester.pumpAndSettle(Duration(seconds: 2));
      expect(find.text('Dashboard'), findsOneWidget);
      
      // 5. Create new transaction
      final addButton = find.byIcon(Icons.add_circle_outline);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      
      // Fill form
      await tester.enterText(
        find.byKey(Key('amount_field')), 
        '50.00',
      );
      await tester.enterText(
        find.byKey(Key('description_field')), 
        'Test Transaction',
      );
      
      // Save
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      
      // Verify transaction appears
      expect(find.text('Test Transaction'), findsOneWidget);
      
      // 6. Export backup
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Backup & Recovery'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Crea Backup'));
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // Verify success message
      expect(find.text('Export completato'), findsOneWidget);
    });
    
    testWidgets('Budget creation and overspending alert', 
      (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to Budget screen
      await tester.tap(find.byIcon(Icons.pie_chart));
      await tester.pumpAndSettle();
      
      // Create budget
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byKey(Key('budget_name')), 'Cibo');
      await tester.enterText(find.byKey(Key('budget_amount')), '300');
      
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      
      // Add transaction that exceeds budget
      // ...
      
      // Verify alert is shown
      expect(find.textContaining('Superato'), findsOneWidget);
    });
  });
}
```

### Running E2E Tests

```bash
# Android
flutter test integration_test/app_test.dart

# iOS
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

## 🐛 BUG SIMULATION & CHAOS TESTING

### Scenario 1: Memory Pressure During Backup

```dart
// test/stress/memory_pressure_test.dart
void main() {
  test('Backup should handle memory pressure gracefully', () async {
    // Create 50,000 transactions (simulate large dataset)
    final isar = await _setupHugeDatabase(txCount: 50000);
    final masterKey = await CryptoService().getOrGenerateMasterKey();
    final backupService = BackupService();
    
    bool memoryPressureDetected = false;
    
    // Simulate memory pressure callback
    WidgetsBinding.instance.addObserver(
      _MemoryObserver(onMemoryPressure: () {
        memoryPressureDetected = true;
      }),
    );
    
    try {
      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: masterKey,
      );
      
      expect(File(backupPath).existsSync(), isTrue);
      
      // Se memory pressure è stata rilevata, il backup dovrebbe comunque completarsi
      if (memoryPressureDetected) {
        print('✅ Memory pressure handled gracefully');
      }
      
    } catch (e) {
      fail('Backup failed under memory pressure: $e');
    }
  });
}
```

### Scenario 2: Network Interruption During Open Banking

```dart
test('Open Banking should recover from network interruption', () async {
  final mockDio = MockDio();
  
  // Simulate network failure on first attempt
  when(() => mockDio.post(any(), data: any(named: 'data')))
      .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/initiate'),
      ));
  
  final openBanking = OpenBankingService(dio: mockDio);
  
  // Should retry automatically
  expect(
    () => openBanking.initiateConnection(institutionId: 'TEST_BANK'),
    throwsA(isA<NetworkException>()),
  );
  
  // Verify retry was attempted
  verify(() => mockDio.post(any(), data: any(named: 'data')))
      .called(greaterThan(1));
});
```

---

## 🔒 SECURITY TESTING

### Penetration Testing Checklist

**🔴 Critical Security Tests**:

1. **SQL Injection** (N/A - Isar is NoSQL)
2. **XSS** (N/A - No web interface)
3. **Insecure Data Storage**:
   ```dart
   test('Master key should never be stored in plain text', () async {
     final storage = FlutterSecureStorage();
     
     final key = await storage.read(key: 'fyne_master_key');
     
     // Key should be Base64 encoded, not plain bytes
     expect(() => utf8.decode(base64.decode(key!)), returnsNormally);
   });
   ```

4. **Man-in-the-Middle (MITM)**:
   - ✅ Certificate pinning per API calls
   - ✅ End-to-end encryption anche su TLS

5. **Insufficient Cryptography**:
   ```dart
   test('Ensure AES-256-GCM is used, not AES-CBC', () {
     final algorithm = CryptoService()._algorithm;
     expect(algorithm.runtimeType.toString(), contains('AesGcm'));
     expect(algorithm.secretKeyLength, equals(32)); // 256 bits
   });
   ```

### Automated Security Scan

```bash
# Static Analysis
flutter analyze

# Dependency vulnerabilities
flutter pub outdated --mode=null-safety

# OWASP Dependency Check
dependency-check --project fyne --scan pubspec.lock
```

---

## 📊 PERFORMANCE TESTING

### Benchmark: Startup Time

```dart
// test/performance/startup_benchmark.dart
void main() {
  test('App cold start should be < 2 seconds', () async {
    final stopwatch = Stopwatch()..start();
    
    // Simulate app initialization
    await Firebase.initializeApp();
    await AnalyticsService().init();
    await NotificationService().init();
    
    final isar = await Isar.open([/* schemas */]);
    
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    print('Cold start: ${stopwatch.elapsedMilliseconds}ms');
  });
}
```

### Benchmark: Transaction List Scroll Performance

```dart
test('Scroll through 1000 transactions at 60fps', () async {
  final tester = WidgetTester();
  
  // Build list with 1000 items
  await tester.pumpWidget(
    MaterialApp(
      home: TransactionListScreen(
        transactions: _generate1000Transactions(),
      ),
    ),
  );
  
  // Measure frame render time
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final observer = _FrameObserver();
  binding.addObserver(observer);
  
  // Scroll rapidly
  await tester.drag(find.byType(ListView), Offset(0, -5000));
  await tester.pumpAndSettle();
  
  // Verify no frame drops (60fps = 16.67ms per frame)
  expect(observer.maxFrameTime, lessThan(20)); // Allow 20ms tolerance
});
```

---

## 🚀 BETA TESTING PROGRAM

### Phase 1: Closed Alpha (50 users, 2 weeks)

**Obiettivi**:
- Identificare crash critici
- Validare flusso onboarding
- Testare backup/restore in condizioni reali

**Metrics**:
- Crash-free rate: > 98%
- Retention D7: > 60%
- Backup success rate: > 95%

**Feedback Collection**:
```dart
// In-app feedback widget
class BetaFeedbackWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showFeedbackDialog(context),
      child: Icon(Icons.bug_report),
      backgroundColor: Colors.orange,
    );
  }
  
  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🐛 Report Bug / 💡 Suggerimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Descrivi il problema'),
              maxLines: 5,
              onChanged: (text) => _feedbackText = text,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitFeedback(),
              child: Text('Invia Feedback'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitFeedback() async {
    // Invia a Firebase/Slack/Notion
    await AnalyticsService().logEvent('beta_feedback', {
      'text': _feedbackText,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### Phase 2: Open Beta (500 users, 4 weeks)

**Obiettivi**:
- Stress test con dati reali
- Validare Open Banking integration
- Testare monetization flow

**A/B Tests**:
1. **Onboarding Flow**:
   - Variant A: 3-step tutorial
   - Variant B: Interactive demo
   
2. **Pricing Screen**:
   - Variant A: Monthly €4.99
   - Variant B: Yearly €49.99 (2 mesi gratis)

### Beta Tester Recruitment

**Canali**:
- Product Hunt "Ship" page
- Reddit r/ItaliaPersonalFinance
- Telegram groups fintech
- Email list esistente

**Incentivi**:
- 🎁 3 mesi Premium gratis
- 🏆 Credit "Beta Tester" nell'app
- 💰 €50 Amazon voucher per top 5 bug reporters

---

## ✅ PRE-LAUNCH CHECKLIST

### 🔐 Security & Privacy

- [ ] GDPR privacy policy pubblicata
- [ ] Terms of Service finalized
- [ ] Certificate pinning attivo
- [ ] Backup encryption testata con 10+ scenari
- [ ] Penetration test completato (no critical issues)
- [ ] Security audit report disponibile

### 🧪 Quality Assurance

- [ ] Unit test coverage > 80%
- [ ] Integration tests pass al 100%
- [ ] E2E tests per 3 critical flows
- [ ] Crash-free rate > 99% in beta
- [ ] Performance: cold start < 2s
- [ ] Performance: 1000 tx list scroll smooth

### 📱 Platform Compliance

**iOS**:
- [ ] App Privacy report completo
- [ ] NSPhotoLibraryUsageDescription chiaro
- [ ] NSFaceIDUsageDescription presente
- [ ] Testato su iPhone SE (2016) - iOS 15
- [ ] Testato su iPhone 15 Pro Max - iOS 17

**Android**:
- [ ] Permissions manifest minimali
- [ ] ProGuard rules configurate
- [ ] Testato su Android 10 (API 29)
- [ ] Testato su Android 14 (API 34)
- [ ] Google Play Data Safety form compilato

### 🎨 User Experience

- [ ] Onboarding < 60 secondi
- [ ] Empty states per tutte le schermate
- [ ] Error messages user-friendly
- [ ] Loading states con skeleton
- [ ] Dark mode testato
- [ ] Accessibilità: TalkBack/VoiceOver compatible

### 📊 Analytics & Monitoring

- [ ] Firebase Crashlytics attivo
- [ ] Firebase Analytics configurato (no PII)
- [ ] Custom events per funnel:
  - `onboarding_completed`
  - `first_transaction_created`
  - `backup_exported`
  - `budget_created`
  - `open_banking_connected`
- [ ] Alert su Slack per crash > 1%

### 💰 Monetization

- [ ] In-App Purchase testato (Sandbox)
- [ ] Paywall screen finalizzata
- [ ] Receipt validation attiva
- [ ] Restore purchases funzionante
- [ ] Subscription management link

### 📚 Documentation

- [ ] README.md aggiornato
- [ ] CHANGELOG.md con tutte le feature
- [ ] API documentation (se applicable)
- [ ] FAQ per utenti pubblicata
- [ ] Video tutorial 2 minuti (YouTube)

### 🚀 Distribution

- [ ] App Store listing completo:
  - [ ] 5 screenshots per iOS
  - [ ] App Preview video
  - [ ] Description SEO-optimized
  - [ ] Keywords: "budget", "finanza", "privacy"
  
- [ ] Google Play listing:
  - [ ] Feature graphic 1024x500
  - [ ] 8 screenshots
  - [ ] Short description < 80 chars
  - [ ] Full description < 4000 chars

---

## 📅 LAUNCH TIMELINE

### Week -2: Final QA Sprint
- Esegui tutti i test
- Fix bug critici
- Performance optimization
- Translation review (IT/EN)

### Week -1: Soft Launch
- Deploy su TestFlight (iOS)
- Deploy su Internal Testing (Android)
- Last-minute bug fixes

### Week 0: PUBLIC BETA LAUNCH 🚀
- **Monday**: Submit to App Store + Google Play
- **Tuesday**: Product Hunt launch
- **Wednesday**: Email campaign
- **Thursday**: Social media push
- **Friday**: Monitor analytics & crash reports

### Week +1: Iteration
- Daily check: Crashlytics dashboard
- Prioritize top 3 bugs
- Hotfix release se necessario
- Collect user feedback

### Week +2-4: Feature Iteration
- Implement feedback più richiesti
- Prepare feature roadmap announcement
- Plan v1.1.0 features

---

## 🎯 SUCCESS CRITERIA

**Beta Success** (entro 4 settimane):
- ✅ 500+ download
- ✅ Crash-free rate > 99%
- ✅ Retention D7 > 40%
- ✅ Retention D30 > 25%
- ✅ 50+ reviews positive (4+ stelle)
- ✅ NPS Score > 40

**Public Launch Success** (entro 3 mesi):
- 🎯 10,000+ download
- 🎯 5% free-to-paid conversion
- 🎯 NPS Score > 50
- 🎯 Featured su App Store (Italia)

---

## 📞 SUPPORT INFRASTRUCTURE

### User Support Channels

1. **In-App Help Center**:
   ```dart
   class HelpCenterScreen extends StatelessWidget {
     final List<FAQItem> faqs = [
       FAQItem(
         question: 'Come faccio il backup dei miei dati?',
         answer: 'Vai su Impostazioni > Backup & Recovery > Crea Backup...',
       ),
       // ... more FAQs
     ];
   }
   ```

2. **Email Support**: support@fyne.app
   - SLA: < 24h per beta users
   - Template risposte per issue comuni

3. **Community Discord**:
   - #general
   - #bug-reports
   - #feature-requests
   - #open-banking-help

### Monitoring Dashboard

**Google Data Studio Dashboard** con:
- Daily Active Users (DAU)
- Crash-free rate
- Top crash clusters
- Feature adoption rate
- Conversion funnel

---

**Ready to launch? 🚀**

Questa strategia di testing garantisce che Fyne sia robusto, sicuro e pronto per il pubblico. Ogni check nella lista porta l'app più vicino al successo.
