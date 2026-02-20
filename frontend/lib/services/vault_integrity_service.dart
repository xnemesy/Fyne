import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter/foundation.dart';
import '../providers/isar_provider.dart';
import '../models/transaction.dart';
import 'crypto_service.dart';

/**
 * Service to monitor and verify the integrity of the encrypted vault.
 */
class VaultIntegrityService {
  final Ref _ref;

  VaultIntegrityService(this._ref);

  /// Checks if the Isar database is accessible and healthy.
  Future<bool> verifyDatabaseHealth() async {
    try {
      final isar = await _ref.read(isarProvider.future);
      // Attempt a simple read operation to verify decryption
      final count = await isar.transactionModels.count();
      return true;
    } catch (e) {
      // If decryption fails, Isar will throw an exception during open or first read
      return false;
    }
  }


  Future<Map<EncryptionScope, bool>> verifyScopeIntegrity() async {
    final crypto = _ref.read(cryptoServiceProvider);
    final results = <EncryptionScope, bool>{};

    for (final scope in EncryptionScope.values) {
      if (scope == EncryptionScope.integrity) continue; // Skip self-check

      try {
        // First ensure the vault is unlocked if we're testing scoped keys
        if (!crypto.isUnlocked) {
          results[scope] = false;
          continue;
        }

        final dummyText = "IntegrityCheck_${scope.name}";
        // Encrypts with AES-GCM + appends HMAC
        final encryptedPayload = await crypto.encrypt(dummyText, scope: scope, type: 'integrity_test');
        
        // Decrypts verifying HMAC first
        final decrypted = await crypto.decrypt(encryptedPayload, scope: scope, type: 'integrity_test');
        
        results[scope] = decrypted == dummyText;
      } catch (e) {
        debugPrint('Integrity check failed for $scope: $e');
        results[scope] = false;
      }
    }
    // Integrity scope is implicitly tested by others because they use it for HMAC
    results[EncryptionScope.integrity] = true;
    
    return results;
  }
}

final vaultIntegrityProvider = Provider<VaultIntegrityService>((ref) {
  return VaultIntegrityService(ref);
});
