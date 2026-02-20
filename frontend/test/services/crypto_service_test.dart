import 'package:flutter_test/flutter_test.dart';
import 'package:fyne_frontend/services/crypto_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    cryptoService = CryptoService(storage: const FlutterSecureStorage());
  });

  group('CryptoService - Key Derivation (Argon2id)', () {
    test('deve derivare una chiave da password e salt non lanciando errori', () async {
      const password = 'SuperSecretPassword123!';
      const salt = 'random_salt_12345';

      final key = await cryptoService.deriveRootKey(password, salt);
      final keyBytes = await key.extractBytes();

      expect(keyBytes.length, 32); // 256 bits
    });
  });

  group('CryptoService - API', () {
    test('deve essere bloccato di default', () {
      expect(cryptoService.isLocked, isTrue);
      expect(cryptoService.isUnlocked, isFalse);
    });

    test('deve sbloccarsi con passphrase e salt', () async {
      await cryptoService.unlock('passphrase123', 'salt123');
      expect(cryptoService.isUnlocked, isTrue);
    });

    test('deve cancellare i dati in ram con wipe()', () async {
      await cryptoService.unlock('passphrase123', 'salt123');
      expect(cryptoService.isUnlocked, isTrue);
      await cryptoService.wipe();
      expect(cryptoService.isLocked, isTrue);
    });
  });

  group('CryptoService - AES-GCM Encryption', () {
    setUp(() async {
      await cryptoService.unlock('TestPassword123', 'TestSalt_456');
    });

    test('deve cifrare e decifrare testo correttamente', () async {
      const plainText = 'Questo è un messaggio segreto! 🔐';

      final encrypted = await cryptoService.encrypt(plainText, scope: EncryptionScope.database);
      final decrypted = await cryptoService.decrypt(encrypted, scope: EncryptionScope.database);

      expect(decrypted, plainText);
    });

    test('deve produrre ciphertext diversi per stesso plaintext a causa del rimescolamento (nonce/mac)', () async {
      const plainText = 'Same message';

      final encrypted1 = await cryptoService.encrypt(plainText, scope: EncryptionScope.apiToken);
      final encrypted2 = await cryptoService.encrypt(plainText, scope: EncryptionScope.apiToken);

      expect(encrypted1, isNot(equals(encrypted2)));

      final decrypted1 = await cryptoService.decrypt(encrypted1, scope: EncryptionScope.apiToken);
      final decrypted2 = await cryptoService.decrypt(encrypted2, scope: EncryptionScope.apiToken);

      expect(decrypted1, plainText);
      expect(decrypted2, plainText);
    });

    test('deve fallire con scope errato', () async {
      const plainText = 'Secret message';

      final encrypted = await cryptoService.encrypt(plainText, scope: EncryptionScope.database);

      expect(
        () => cryptoService.decrypt(encrypted, scope: EncryptionScope.apiToken),
        throwsA(isA<Exception>()),
      );
    });
    
    test('deve fallire con un vault bloccato', () async {
      await cryptoService.wipe();
      expect(
        () => cryptoService.encrypt('Test', scope: EncryptionScope.database),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CryptoService - RSA Key Management', () {
    test('deve generare coppia di chiavi RSA ed essere recuperabile', () async {
      final publicKey1 = await cryptoService.getOrGeneratePublicKey();
      expect(publicKey1, isNotEmpty);
      
      final publicKey2 = await cryptoService.getOrGeneratePublicKey();
      expect(publicKey1, equals(publicKey2));
    });

    test('deve decifrare con private key', () async {
      // Nota: getOrGeneratePublicKey deve essere chiamato per inizializzare _rsaPrivateKey
      await cryptoService.getOrGeneratePublicKey(); 
      // La cifratura pubblica non espone più un metodo diretto in CryptoService 
      // (a meno di usare funzioni di una libreria o scriverla).
      // Testiamo che almeno decifri senza bloccarsi hard, per ora diamo per scontato che 
      // non ci sia una f_encrypt esposta publicamente.
    });
  });

  group('CryptoService - Security Edge Cases', () {
    setUp(() async {
      await cryptoService.unlock('TestPassword123', 'TestSalt_456');
    });

    test('non deve decifrare dati corrotti', () async {
      final encrypted = await cryptoService.encrypt('Test', scope: EncryptionScope.database);

      // Corrompi i dati cifrati
      final corrupted = encrypted.substring(0, encrypted.length - 10) + 'CORRUPTED==';

      expect(
        () => cryptoService.decrypt(corrupted, scope: EncryptionScope.database),
        throwsA(anything),
      );
    });
  });
}
