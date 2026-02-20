import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/services/crypto_service.dart';

void main() {
  FlutterSecureStorage.setMockInitialValues({
    'fyne_vault_salt': 'dGVzdXNhbHQxMjM0NTY3OA==',
  });

  group('Tink Zero-Knowledge Hardening Tests (v2.3)', () {
    final crypto = CryptoService(storage: const FlutterSecureStorage());

    setUpAll(() async {
      await crypto.unlock('master_password', 'user_salt');
    });

    test('1. Metadata Integrity (expiresAt in Envelope)', () async {
      final envelope = {
        'token': 'tink_access_token_123',
        'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      };
      
      final encrypted = await crypto.encrypt(
        jsonEncode(envelope),
        scope: EncryptionScope.apiToken,
        type: 'access_envelope',
        contextId: 'tink:acc_1',
      );

      // Verify healthy decryption
      final decrypted = await crypto.decrypt(
        encrypted,
        scope: EncryptionScope.apiToken,
        type: 'access_envelope',
        contextId: 'tink:acc_1',
      );
      expect(jsonDecode(decrypted)['token'], 'tink_access_token_123');

      // Attempt Tampering (metadata is inside ciphertext, so HMAC will catch it)
      final bytes = base64.decode(encrypted);
      bytes[bytes.length - 1] ^= 0x01; // Modify ciphertext
      final tampered = base64.encode(bytes);

      expect(
        () => crypto.decrypt(tampered, scope: EncryptionScope.apiToken, type: 'access_envelope', contextId: 'tink:acc_1'),
        throwsA(predicate((e) => e.toString().contains('HMAC mismatch'))),
      );
    });

    test('2. Replay Prevention (AAD Context Binding)', () async {
      const provider1 = 'tink:bank_alpha';
      const provider2 = 'tink:bank_beta';
      const token = 'secret_token';

      final encryptedForP1 = await crypto.encrypt(
        token,
        scope: EncryptionScope.apiToken,
        type: 'access_token',
        contextId: provider1,
      );

      // Attempt to use P1's encrypted token for P2
      // This should fail even if keys are the same because AAD (providerId) is different
      expect(
        () => crypto.decrypt(encryptedForP1, scope: EncryptionScope.apiToken, type: 'access_token', contextId: provider2),
        throwsA(predicate((e) => 
          e.toString().contains('wrong message authentication code') || 
          e.toString().contains('HMAC mismatch') ||
          e.toString().contains('AES GCM authentication failed'))),
        reason: 'Should fail because AAD context (providerId) does not match.',
      );
      
      // Confirmation: works for P1
      final decrypted = await crypto.decrypt(encryptedForP1, scope: EncryptionScope.apiToken, type: 'access_token', contextId: provider1);
      expect(decrypted, token);
    });
  });
}
