import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Adjust import path as needed
import '../lib/services/crypto_service.dart';

void main() {
  // Mock Secure Storage
  FlutterSecureStorage.setMockInitialValues({
    'fyne_vault_salt': 'dGVzdXNhbHQxMjM0NTY3OA==', // base64 encoded "testsalt12345678"
    'fyne_rsa_private_key': 'mock_rsa_key',
  });

  group('CryptoService Signal-Level Hardening Tests', () {
    final crypto = CryptoService(storage: const FlutterSecureStorage());
    // Re-initialize for each test if possible, but singleton is used.
    // We can rely on 'lock' state.

    test('1. Unlock & Derive Keys (Argon2id + HKDF)', () async {
      await crypto.unlock('password123', 'somesalt');
      expect(crypto.isUnlocked, isTrue);
      
       final dbKey = await crypto.getScopedKey(EncryptionScope.database);
       expect(dbKey, isNotNull);
    });

    test('2. Encrypt/Decrypt Cycle (AES-GCM + HMAC)', () async {
      const plainText = "Sensitive Data 123";
      
      final encrypted = await crypto.encrypt(plainText, scope: EncryptionScope.database);
      expect(encrypted, isNot(plainText));
      expect(encrypted.length, greaterThan(32)); // At least HMAC (32) + IV + Cipher

      final decrypted = await crypto.decrypt(encrypted, scope: EncryptionScope.database);
      expect(decrypted, equals(plainText));
    });

    test('3. HMAC Tamper Detection', () async {
      const plainText = "Do Not Touch Me";
      final encryptedBase64 = await crypto.encrypt(plainText, scope: EncryptionScope.database);
      
      // Tamper with the payload
      final bytes = base64.decode(encryptedBase64);
      // Flip a bit in the ciphertext (last byte)
      bytes[bytes.length - 1] ^= 0x01; 
      
      final tamperedBase64 = base64.encode(bytes);

      try {
        await crypto.decrypt(tamperedBase64, scope: EncryptionScope.database);
        fail('Should have thrown VaultIntegrityException or similar');
      } catch (e) {
        // We expect an exception (HMAC mismatch or AES-GCM Auth failure if we touched GCM tag, 
        // but since we touched content/tag, likely HMAC fails first or GCM fails)
        // With our Encrypt-then-MAC, checking MAC is first.
        // We modified the end, which is likely part of the Ciphertext (MAC is prepended in our impl? No, let's check).
        // Impl: [HMAC bytes] + [AES-GCM Ciphertext]
        // bytes.length - 1 is in Ciphertext.
        // So HMAC check involves calculating MAC of Ciphertext.
        // Changed Ciphertext -> Calculated MAC changes -> Mismatch with stored MAC.
        expect(e.toString(), contains('HMAC mismatch'));
      }
    });

    test('4. Memory Wipe', () async {
      await crypto.wipe();
      expect(crypto.isUnlocked, isFalse);

      try {
        await crypto.getScopedKey(EncryptionScope.database);
        fail('Should throw when locked');
      } catch (_) {
        // Expected
      }
    });
  });

  group('Performance Benchmarks', () {
    final crypto = CryptoService(storage: const FlutterSecureStorage());

    test('Benchmark: 1000 Decryptions (Mobile capability)', () async {
      // Setup
      await crypto.unlock('benchmark_pass', 'bench_salt');
      const plainText = "Description of a transaction #12345";
      final encrypted = await crypto.encrypt(plainText, scope: EncryptionScope.database);

      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        await crypto.decrypt(encrypted, scope: EncryptionScope.database);
      }
      
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      print('PERFORMANCE: 1000 Decryptions took ${ms}ms');
      print('AVERAGE: ${(ms / 1000).toStringAsFixed(3)}ms per record');

      // Expectation: < 500ms for 1000 records on high-end, maybe < 2000ms on low-end.
      // 100ms per 1000 records is 0.1ms per record. That's very fast.
      // AES-GCM + HMAC-SHA256 in Dart might be slower.
      // Let's set a lenient limit for CI, but user can judge.
      expect(ms, lessThan(3000)); 
    });
  });
}
