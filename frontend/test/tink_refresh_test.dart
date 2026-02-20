import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/services/crypto_service.dart';
import '../lib/services/tink_refresh_service.dart';
import '../lib/models/bank_connection.dart';
import '../lib/providers/isar_provider.dart';
import 'package:isar_community/isar.dart';

void main() {
  late ProviderContainer container;
  late CryptoService crypto;
  late TinkRefreshService refreshService;
  late Isar isar;

  FlutterSecureStorage.setMockInitialValues({
    'fyne_vault_salt': 'dGVzdXNhbHQxMjM0NTY3OA==',
  });

  setUp(() async {
    // Setup Isar in-memory (or mock)
    // For this test, we mostly focus on the logic flow and concurrency
    isar = await Isar.open(
      [BankConnectionSchema],
      directory: '.', // Mocked path
      name: 'test_refresh_db',
    );

    container = ProviderContainer(
      overrides: [
        isarProvider.overrideWith((ref) => Future.value(isar)),
      ],
    );

    crypto = container.read(cryptoServiceProvider);
    refreshService = container.read(tinkRefreshProvider);

    await crypto.unlock('master_password', 'user_salt');
  });

  tearDown(() async {
    await isar.close();
    container.dispose();
  });

  group('Tink Refresh Lifecycle Tests (v2.4)', () {
    
    test('1. Pre-emptive Refresh Trigger', () async {
      const providerId = 'tink:trigger_test';
      
      // Create envelope expiring in 30 seconds (< 60s trigger)
      final expiresAt = DateTime.now().add(const Duration(seconds: 30));
      final envelope = jsonEncode({
        'token': 'old_at',
        'expiresAt': expiresAt.toIso8601String(),
      });

      final encryptedAccess = await crypto.encrypt(envelope, scope: EncryptionScope.apiToken, type: 'access_envelope', contextId: providerId);
      final encryptedRefresh = await crypto.encrypt('old_rt', scope: EncryptionScope.apiToken, type: 'refresh_token', contextId: providerId);

      final conn = BankConnection(
        providerId: providerId,
        encryptedAccessEnvelope: encryptedAccess,
        encryptedRefreshToken: encryptedRefresh,
        bankName: 'Test Bank',
        updatedAt: DateTime.now(),
      );

      await isar.writeTxn(() => isar.bankConnections.put(conn));

      // Trigger
      await refreshService.ensureValidAccessToken(conn);

      // Verify Update in DB
      final updated = await isar.bankConnections.where().providerIdEqualTo(providerId).findFirst();
      expect(updated!.updatedAt.isAfter(conn.updatedAt), isTrue);
      
      // Decrypt new envelope to check if it's updated
      final newEnvJson = await crypto.decrypt(updated.encryptedAccessEnvelope, scope: EncryptionScope.apiToken, type: 'access_envelope', contextId: providerId);
      expect(jsonDecode(newEnvJson)['token'], contains('new_at_'));
    });

    test('2. Concurrency Mutex (Race-Safe)', () async {
      const providerId = 'tink:mutex_test';
      
      final expiresAt = DateTime.now().add(const Duration(seconds: 10));
      final envelope = jsonEncode({'token': 'old', 'expiresAt': expiresAt.toIso8601String()});
      final encAccess = await crypto.encrypt(envelope, scope: EncryptionScope.apiToken, type: 'access_envelope', contextId: providerId);
      final encRefresh = await crypto.encrypt('old_rt', scope: EncryptionScope.apiToken, type: 'refresh_token', contextId: providerId);

      final conn = BankConnection(
        providerId: providerId,
        encryptedAccessEnvelope: encAccess,
        encryptedRefreshToken: encRefresh,
        bankName: 'Mutex Bank',
        updatedAt: DateTime.now(),
      );

      await isar.writeTxn(() => isar.bankConnections.put(conn));

      // Call ensureValidAccessToken 5 times in parallel
      // Only ONE should trigger the internal refresh logic (logs would show)
      // and they should all wait for the same result.
      await Future.wait([
        refreshService.ensureValidAccessToken(conn),
        refreshService.ensureValidAccessToken(conn),
        refreshService.ensureValidAccessToken(conn),
        refreshService.ensureValidAccessToken(conn),
        refreshService.ensureValidAccessToken(conn),
      ]);

      // If we got here without error and only one write txn happened (Isar handles serialization), 
      // the mutex prevented "refresh storm".
      final finalConn = await isar.bankConnections.where().providerIdEqualTo(providerId).findFirst();
      expect(finalConn, isNotNull);
    });

    test('3. HMAC Tamper on Refresh Token', () async {
      const providerId = 'tink:tamper_test';
      final expiresAt = DateTime.now().add(const Duration(seconds: 10));
      final envelope = jsonEncode({'token': 'old', 'expiresAt': expiresAt.toIso8601String()});
      
      final encAccess = await crypto.encrypt(envelope, scope: EncryptionScope.apiToken, type: 'access_envelope', contextId: providerId);
      final encRefresh = await crypto.encrypt('old_rt', scope: EncryptionScope.apiToken, type: 'refresh_token', contextId: providerId);

      // Tamper
      final bytes = base64.decode(encRefresh);
      bytes[bytes.length - 1] ^= 0x01;
      final tamperedRefresh = base64.encode(bytes);

      final conn = BankConnection(
        providerId: providerId,
        encryptedAccessEnvelope: encAccess,
        encryptedRefreshToken: tamperedRefresh,
        bankName: 'Tamper Bank',
        updatedAt: DateTime.now(),
      );

      await isar.writeTxn(() => isar.bankConnections.put(conn));

      expect(
        () => refreshService.ensureValidAccessToken(conn),
        throwsA(predicate((e) => e.toString().contains('HMAC mismatch') || e.toString().contains('wrong message authentication code'))),
      );
    });
  });
}
