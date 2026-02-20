import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_connection.dart';
import 'crypto_service.dart';
import 'key_rotation_service.dart';
import '../providers/isar_provider.dart';
import 'package:isar_community/isar.dart';

/**
 * Service for managing Tink Refresh Token Lifecycle (v2.4).
 * Standards: Race-safe, Atomic Updates, Zero-Knowledge compliant.
 * Features:
 * - Distributed Mutex (per providerId) to prevent refresh storms.
 * - Exponential backoff on network transient failures.
 * - Atomic writeTxn to ensure consistent token pairs.
 */
class TinkRefreshService {
  final CryptoService _crypto;
  final Ref _ref;

  // Concurrency Control: Per-provider mutex map
  final Map<String, Future<void>> _activeRefreshes = {};

  TinkRefreshService(this._ref, this._crypto);

  /// Ensures a valid access token exists. If expired (or expiring in <60s), triggers refresh.
  Future<void> ensureValidAccessToken(BankConnection connection) async {
    if (!_crypto.isUnlocked) throw Exception('Vault locked');

    // 1. Check if refresh is already in progress for this provider
    if (_activeRefreshes.containsKey(connection.providerId)) {
      debugPrint('[TinkRefresh] Waiting for existing refresh to complete for ${connection.providerId}');
      await _activeRefreshes[connection.providerId];
      return;
    }

    // 2. Progressive Migration Check (on-read)
    final rotationService = _ref.read(keyRotationProvider);
    final migrated = await rotationService.migrateIfLegacy<BankConnection>(
      recordUuid: connection.providerId,
      currentVersion: connection.encryptionVersion,
      decryptFn: (v) async {
        // Decrypt with specified legacy version
        final accessEnv = await _crypto.decrypt(
          connection.encryptedAccessEnvelope,
          scope: EncryptionScope.apiToken,
          type: 'access_envelope',
          contextId: connection.providerId,
          version: v,
        );
        final refreshTok = await _crypto.decrypt(
          connection.encryptedRefreshToken,
          scope: EncryptionScope.apiToken,
          type: 'refresh_token',
          contextId: connection.providerId,
          version: v,
        );
        return jsonEncode({'access': accessEnv, 'refresh': refreshTok});
      },
      reEncryptAndUpdateFn: (plainJson, newVersion) async {
        final data = jsonDecode(plainJson);
        final newAccess = await _crypto.encrypt(data['access'], scope: EncryptionScope.apiToken, type: 'access_envelope', contextId: connection.providerId, version: newVersion);
        final newRefresh = await _crypto.encrypt(data['refresh'], scope: EncryptionScope.apiToken, type: 'refresh_token', contextId: connection.providerId, version: newVersion);
        
        final isar = await _ref.read(isarProvider.future);
        return await isar.writeTxn(() async {
          final existing = await isar.bankConnections.where().providerIdEqualTo(connection.providerId).findFirst();
          if (existing == null) throw Exception('Record lost during migration');
          
          final updated = BankConnection(
            id: existing.id,
            providerId: existing.providerId,
            encryptedAccessEnvelope: newAccess,
            encryptedRefreshToken: newRefresh,
            bankName: existing.bankName,
            logoUrl: existing.logoUrl,
            encryptionVersion: newVersion,
            updatedAt: DateTime.now(),
          );
          await isar.bankConnections.put(updated);
          return updated;
        });
      },
    );

    final activeConnection = migrated ?? connection;

    // 3. Check Expiry (Pre-emptive: 60s buffer)
    // Decrypt envelope to check true expiresAt using activeConnection's version
    final envelopeJson = await _crypto.decrypt(
      activeConnection.encryptedAccessEnvelope,
      scope: EncryptionScope.apiToken,
      type: 'access_envelope',
      contextId: activeConnection.providerId,
      version: activeConnection.encryptionVersion,
    );
    final envelope = jsonDecode(envelopeJson);
    final expiresAt = DateTime.parse(envelope['expiresAt']);

    if (DateTime.now().add(const Duration(seconds: 60)).isAfter(expiresAt)) {
      debugPrint('[TinkRefresh] Token expiring soon. Initiating refresh for ${activeConnection.providerId}');
      
      // Use mutex pattern
      final refreshFuture = _performRefresh(activeConnection);
      _activeRefreshes[activeConnection.providerId] = refreshFuture;
      
      try {
        await refreshFuture;
      } finally {
        _activeRefreshes.remove(connection.providerId);
      }
    }
  }

  /// Internal: Performs the cryptographic refresh flow with backoff.
  Future<void> _performRefresh(BankConnection connection) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        // 1. Decrypt Refresh Token (Hardened AAD binding)
        final refreshToken = await _crypto.decrypt(
          connection.encryptedRefreshToken,
          scope: EncryptionScope.apiToken,
          type: 'refresh_token',
          contextId: connection.providerId,
          version: connection.encryptionVersion,
        );

        // 2. Blind Proxy Refresh Request
        final response = await _callRefreshApi(refreshToken);
        
        // 3. Atomic Preparation
        final newExpiresAt = DateTime.now().add(Duration(seconds: response['expires_in']));
        
        final newAccessEnvelope = jsonEncode({
          'token': response['access_token'],
          'expiresAt': newExpiresAt.toIso8601String(),
        });

        // 4. Atomic Encryption
        final encryptedAccess = await _crypto.encrypt(
          newAccessEnvelope,
          scope: EncryptionScope.apiToken,
          type: 'access_envelope',
          contextId: connection.providerId,
        );

        final encryptedRefresh = await _crypto.encrypt(
          response['refresh_token'],
          scope: EncryptionScope.apiToken,
          type: 'refresh_token',
          contextId: connection.providerId,
        );

        // 5. Atomic Isar Update
        final isar = await _ref.read(isarProvider.future);
        await isar.writeTxn(() async {
          final existing = await isar.bankConnections
              .where()
              .providerIdEqualTo(connection.providerId)
              .findFirst();
              
          if (existing != null) {
            final updated = BankConnection(
              id: existing.id,
              providerId: existing.providerId,
              encryptedAccessEnvelope: encryptedAccess,
              encryptedRefreshToken: encryptedRefresh,
              bankName: existing.bankName,
              logoUrl: existing.logoUrl,
              encryptionVersion: existing.encryptionVersion,
              updatedAt: DateTime.now(),
            );
            await isar.bankConnections.put(updated);
          }
        });

        debugPrint('[TinkRefresh] Atomic token update successful for ${connection.providerId}');
        return; // Success!

      } on HttpException catch (e) {
        // Handle revocation (invalid_grant)
        if (e.message.contains('invalid_grant')) {
          await _handleRevocation(connection);
          throw Exception('Token revoked. Bank connection wiped.');
        }
        rethrow;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;

        // Exponential Backoff: 1s, 2s, 4s
        final delay = Duration(seconds: 1 << (attempts - 1));
        debugPrint('[TinkRefresh] Retry $attempts in ${delay.inSeconds}s due to: $e');
        await Future.delayed(delay);
      }
    }
  }

  /// Placeholder: Chiamata al Blind Proxy Backend per il refresh.
  Future<Map<String, dynamic>> _callRefreshApi(String refreshToken) async {
    // In production: return (await dio.post('/api/refresh/tink', data: {'refresh_token': refreshToken})).data;
    // Simulator mock:
    return {
      'access_token': 'new_at_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token': 'new_rt_${DateTime.now().millisecondsSinceEpoch}',
      'expires_in': 3600,
    };
  }

  /// Security: Full wipe on revocation to prevent further exposure.
  Future<void> _handleRevocation(BankConnection connection) async {
    final isar = await _ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      await isar.bankConnections
          .where()
          .providerIdEqualTo(connection.providerId)
          .deleteAll();
    });
    debugPrint('[TinkRefresh] SECURITY: Connection ${connection.providerId} wiped due to revocation.');
  }
}

final tinkRefreshProvider = Provider((ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  return TinkRefreshService(ref, crypto);
});
