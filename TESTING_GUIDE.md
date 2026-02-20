# 🧪 Testing & Quality Assurance - Fyne Banking

## 📚 Indice
- [Setup Ambiente](#setup-ambiente)
- [Esecuzione Test](#esecuzione-test)
- [Coverage Report](#coverage-report)
- [Test Disponibili](#test-disponibili)
- [Best Practices](#best-practices)

---

## 🔧 Setup Ambiente

### Prerequisiti
```bash
# Assicurati di avere Flutter installato
flutter --version

# Installa le dipendenze
flutter pub get

# Genera i file Isar
flutter pub run build_runner build --delete-conflicting-outputs
```

### Setup Test Environment
```bash
# Le dipendenze per il testing sono già in pubspec.yaml:
# - flutter_test
# - isar (con supporto in-memory per test)
# - cryptography
```

---

## ▶️ Esecuzione Test

### Esegui TUTTI i test
```bash
flutter test
```

### Esegui test specifici
```bash
# Test per TransactionRepository
flutter test test/repositories/transaction_repository_test.dart

# Test per BackupService
flutter test test/services/backup_service_test.dart

# Test per CryptoService
flutter test test/services/crypto_service_test.dart
```

### Esegui test con output verboso
```bash
flutter test --verbose
```

### Esegui test in watch mode (auto-reload)
```bash
flutter test --watch
```

---

## 📊 Coverage Report

### Genera report di coverage
```bash
# Installa lcov (se non già presente)
# macOS: brew install lcov
# Linux: sudo apt-get install lcov

# Genera coverage
flutter test --coverage

# Genera report HTML
genhtml coverage/lcov.info -o coverage/html

# Apri il report nel browser
open coverage/html/index.html
```

### Target di Coverage
- **Obiettivo minimo**: 80% di coverage
- **Target ideale**: 90%+ su logica critica (crypto, backup, transazioni)

---

## 📋 Test Disponibili

### 1️⃣ Transaction Repository Tests
**File**: `test/repositories/transaction_repository_test.dart`

**Cosa testa**:
- ✅ Encryption/Decryption di transazioni
- ✅ Paginazione con dati cifrati
- ✅ Operazioni CRUD (Create, Read, Update, Delete)
- ✅ Gestione errori con chiave errata
- ✅ Edge cases (importi negativi, caratteri speciali, decimali)

**Esecuzione**:
```bash
flutter test test/repositories/transaction_repository_test.dart -r expanded
```

**Output atteso**:
```
✓ deve cifrare e salvare una transazione correttamente
✓ deve gestire correttamente la paginazione cifrata
✓ deve fallire con chiave master errata
✓ deve eliminare correttamente una transazione
✓ deve gestire importi negativi (uscite)
✓ deve gestire caratteri speciali nella descrizione
✓ deve gestire importi decimali con alta precisione

All tests passed! (7/7)
```

---

### 2️⃣ Backup Service Tests
**File**: `test/services/backup_service_test.dart`

**Cosa testa**:
- ✅ Export di backup cifrato
- ✅ Validazione backup (checksum integrity)
- ✅ Import e ripristino dati
- ✅ Rilevamento backup corrotto
- ✅ Gestione chiave master errata
- ✅ Progress tracking durante export/import
- ✅ Edge cases (database vuoto, grandi quantità di dati)

**Esecuzione**:
```bash
flutter test test/services/backup_service_test.dart -r expanded
```

**Output atteso**:
```
✓ deve esportare backup cifrato con successo
✓ deve validare backup prima dell'import
✓ deve importare backup e ripristinare i dati
✓ deve rilevare backup corrotto (checksum mismatch)
✓ deve fallire con chiave master errata
✓ deve tracciare il progresso dell'export
✓ deve gestire database vuoto
✓ deve gestire grandi quantità di dati

All tests passed! (8/8)
```

---

### 3️⃣ Crypto Service Tests
**File**: `test/services/crypto_service_test.dart`

**Cosa testa**:
- ✅ Derivazione chiave PBKDF2 da password e salt
- ✅ AES-GCM encryption/decryption
- ✅ Gestione nonce randomici (stesso plaintext → diversi ciphertext)
- ✅ Validazione MAC (authenticated encryption)
- ✅ RSA key pair generation e persistenza
- ✅ Master key generation e storage
- ✅ Edge cases (stringhe vuote, caratteri speciali, testo lungo)
- ✅ Security tests (dati corrotti, MAC tampering)

**Esecuzione**:
```bash
flutter test test/services/crypto_service_test.dart -r expanded
```

**Output atteso**:
```
✓ deve derivare una chiave da password e salt
✓ deve generare chiavi diverse con salt diversi
✓ deve generare sempre la stessa chiave con stessi input
✓ deve cifrare e decifrare testo correttamente
✓ deve produrre ciphertext diversi per stesso plaintext
✓ deve fallire con chiave errata
✓ deve gestire stringhe vuote
✓ deve gestire caratteri speciali e emoji
✓ deve gestire testo molto lungo
✓ deve generare e persistere master key
✓ deve generare coppia di chiavi RSA
✓ deve cifrare con public key e decifrare con private key
✓ non deve decifrare dati corrotti
✓ deve validare l'integrità con MAC

All tests passed! (14/14)
```

---

## 🎯 Best Practices

### Scrivere Nuovi Test

#### 1. Struttura Standard
```dart
void main() {
  late YourService service;
  
  setUp(() {
    // Setup prima di ogni test
    service = YourService();
  });
  
  tearDown(() {
    // Cleanup dopo ogni test
    service.dispose();
  });

  group('Feature Name', () {
    test('should do something', () async {
      // Arrange
      final input = 'test data';
      
      // Act
      final result = await service.doSomething(input);
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

#### 2. Naming Conventions
```dart
// ✅ GOOD: Descrittivo e chiaro
test('deve cifrare e salvare una transazione correttamente', () {});
test('deve fallire con chiave master errata', () {});
test('deve gestire caratteri speciali nella descrizione', () {});

// ❌ BAD: Generico o poco chiaro
test('test1', () {});
test('it works', () {});
```

#### 3. Coverage Critica
Assicurati di testare:
- ✅ Happy path (flusso normale)
- ✅ Edge cases (valori limite, input inusuali)
- ✅ Error handling (cosa succede quando fallisce)
- ✅ Security (validazione, tampering, chiavi errate)

#### 4. Mock vs Real Objects
```dart
// Per servizi esterni → Mock
final mockApiClient = MockApiClient();

// Per logica interna → Real objects
final cryptoService = CryptoService(); // No mock
```

---

## 🚨 Troubleshooting

### Test falliti: "Isar not found"
```bash
# Rigenera i file Isar
flutter pub run build_runner build --delete-conflicting-outputs
```

### Test falliti: "SecureStorage mock error"
```dart
// Aggiungi al setUp():
FlutterSecureStorage.setMockInitialValues({});
```

### Test lenti
```bash
# Esegui solo un subset
flutter test test/services/ --exclude-tags=slow

# O parallelizza
flutter test -j 4  # 4 workers in parallelo
```

---

## 📈 CI/CD Integration

### GitHub Actions Example
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter pub run build_runner build
      - run: flutter test --coverage
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

---

## 📝 Checklist Pre-Release

Prima di ogni release, verifica che:
- [ ] Tutti i test passino: `flutter test`
- [ ] Coverage > 80%: `flutter test --coverage`
- [ ] Nessun warning: `flutter analyze`
- [ ] Build iOS/Android: `flutter build ios/apk`
- [ ] Test manuale su dispositivo reale
- [ ] Backup & Restore funzionano correttamente
- [ ] Encryption/Decryption performance OK

---

## 🎓 Risorse Utili

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Isar Testing](https://isar.dev/recipes/test.html)
- [Cryptography Package](https://pub.dev/packages/cryptography)

---

**Fatto con ❤️ per Fyne Banking**
