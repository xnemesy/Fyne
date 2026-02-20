import 'package:flutter_test/flutter_test.dart';
import 'package:fyne_frontend/services/crypto_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    cryptoService = CryptoService();
  });

  group('CryptoService - Key Derivation (PBKDF2)', () {
    test('deve derivare una chiave da password e salt', () async {
      const password = 'SuperSecretPassword123!';
      const salt = 'random_salt_12345';

      final key = await cryptoService.deriveKey(password, salt);
      final keyBytes = await key.extractBytes();

      expect(keyBytes.length, 32); // 256 bits
    });

    test('deve generare chiavi diverse con salt diversi', () async {
      const password = 'SamePassword';
      const salt1 = 'salt_one';
      const salt2 = 'salt_two';

      final key1 = await cryptoService.deriveKey(password, salt1);
      final key2 = await cryptoService.deriveKey(password, salt2);

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, isNot(equals(bytes2)));
    });

    test('deve generare sempre la stessa chiave con stessi input', () async {
      const password = 'ConsistentPassword';
      const salt = 'consistent_salt';

      final key1 = await cryptoService.deriveKey(password, salt);
      final key2 = await cryptoService.deriveKey(password, salt);

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, equals(bytes2));
    });
  });

  group('CryptoService - AES-GCM Encryption', () {
    test('deve cifrare e decifrare testo correttamente', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';
      const plainText = 'Questo è un messaggio segreto! 🔐';

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt(plainText, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, plainText);
    });

    test('deve produrre ciphertext diversi per stesso plaintext', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';
      const plainText = 'Same message';

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted1 = await cryptoService.encrypt(plainText, key);
      final encrypted2 = await cryptoService.encrypt(plainText, key);

      // Ciphertext dovrebbero essere diversi (diverso nonce/IV)
      expect(encrypted1, isNot(equals(encrypted2)));

      // Ma entrambi dovrebbero decifrare allo stesso plaintext
      final decrypted1 = await cryptoService.decrypt(encrypted1, key);
      final decrypted2 = await cryptoService.decrypt(encrypted2, key);

      expect(decrypted1, plainText);
      expect(decrypted2, plainText);
    });

    test('deve fallire con chiave errata', () async {
      const password = 'CorrectPassword';
      const wrongPassword = 'WrongPassword';
      const salt = 'test_salt';
      const plainText = 'Secret message';

      final correctKey = await cryptoService.deriveKey(password, salt);
      final wrongKey = await cryptoService.deriveKey(wrongPassword, salt);

      final encrypted = await cryptoService.encrypt(plainText, correctKey);

      expect(
        () => cryptoService.decrypt(encrypted, wrongKey),
        throwsA(isA<Exception>()),
      );
    });

    test('deve gestire stringhe vuote', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';
      const emptyText = '';

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt(emptyText, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, emptyText);
    });

    test('deve gestire caratteri speciali e emoji', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';
      const specialText = 'Café ☕ & 日本語 + Emoji 🎉🔐💰';

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt(specialText, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, specialText);
    });

    test('deve gestire testo molto lungo', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';
      final longText = 'A' * 10000; // 10k caratteri

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt(longText, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, longText);
    });
  });

  group('CryptoService - Master Key Management', () {
    test('deve generare e persistere master key', () async {
      final masterKey1 = await cryptoService.getOrGenerateMasterKey();
      final masterKey2 = await cryptoService.getOrGenerateMasterKey();

      final bytes1 = await masterKey1.extractBytes();
      final bytes2 = await masterKey2.extractBytes();

      // Dovrebbe restituire la stessa chiave (persistita)
      expect(bytes1, equals(bytes2));
    });

    test('la master key dovrebbe essere di 32 bytes', () async {
      final masterKey = await cryptoService.getOrGenerateMasterKey();
      final bytes = await masterKey.extractBytes();

      expect(bytes.length, 32);
    });
  });

  group('CryptoService - RSA Key Management', () {
    test('deve generare coppia di chiavi RSA', () async {
      final publicKey = await cryptoService.getOrGeneratePublicKey();

      expect(publicKey, isNotEmpty);
      expect(publicKey, contains('-----BEGIN PUBLIC KEY-----'));
    });

    test('deve cifrare con public key e decifrare con private key', () async {
      const testMessage = 'Hello RSA Encryption!';

      await cryptoService.getOrGeneratePublicKey(); // Genera chiavi
      final encrypted = await cryptoService.encryptWithSelfPublicKey(testMessage);
      final decrypted = await cryptoService.decryptWithPrivateKey(encrypted);

      expect(decrypted, testMessage);
    });

    test('deve persistere la private key', () async {
      final publicKey1 = await cryptoService.getOrGeneratePublicKey();
      final publicKey2 = await cryptoService.getOrGeneratePublicKey();

      // Dovrebbe restituire la stessa public key (stessa coppia persistita)
      expect(publicKey1, equals(publicKey2));
    });
  });

  group('CryptoService - Security Edge Cases', () {
    test('non deve decifrare dati corrotti', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt('Test', key);

      // Corrompi i dati cifrati
      final corrupted = encrypted.substring(0, encrypted.length - 10) + 'CORRUPTED==';

      expect(
        () => cryptoService.decrypt(corrupted, key),
        throwsA(anything),
      );
    });

    test('deve validare l\'integrità con MAC', () async {
      const password = 'TestPassword';
      const salt = 'test_salt';
      const plainText = 'Authenticated message';

      final key = await cryptoService.deriveKey(password, salt);
      final encrypted = await cryptoService.encrypt(plainText, key);

      // AES-GCM include MAC - modifica dovrebbe causare failure
      final modifiedEncrypted = encrypted.replaceRange(10, 15, 'XXXXX');

      expect(
        () => cryptoService.decrypt(modifiedEncrypted, key),
        throwsA(anything),
      );
    });
  });
}
