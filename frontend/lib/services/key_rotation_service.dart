import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crypto_service.dart';

/**
 * Service for Progressive Key Rotation (v2.5).
 * Implements "Lazy Migration on Read" strategy.
 * Standards: Crash-safe, Atomic, Race-safe.
 */
class KeyRotationService {
  final CryptoService _crypto;
  final Ref _ref;

  // Emergency Kill-switch (Configurable via Remote Config)
  bool _isMigrationEnabled = true;

  // Per-record migration locks to prevent double migration
  final Map<String, Future<void>> _migrationLocks = {};

  KeyRotationService(this._ref, this._crypto);

  void setMigrationEnabled(bool enabled) {
    _isMigrationEnabled = enabled;
  }

  /// Migrates a record if its encryptionVersion is legacy.
  /// Standards: Sequential, Sync-aware, Crash-safe.
  Future<T?> migrateIfLegacy<T>({
    required String recordUuid,
    required int currentVersion,
    required Future<String> Function(int version) decryptFn,
    required Future<T> Function(String plainText, int newVersion) reEncryptAndUpdateFn,
  }) async {
    // 0. Safety Checks
    if (!_isMigrationEnabled) return null;
    if (currentVersion >= CryptoService.currentCryptoVersion) return null;

    // 2. Acquire per-record lock
    if (_migrationLocks.containsKey(recordUuid)) {
      await _migrationLocks[recordUuid];
      return null;
    }

    final migrationCompleter = Completer<void>();
    _migrationLocks[recordUuid] = migrationCompleter.future;

    try {
      if (kDebugMode) {
        debugPrint('[KeyRotation] Starting migration for $recordUuid from v$currentVersion to v${CryptoService.currentCryptoVersion}');
      }

      // 3. Decrypt with legacy key
      final plainText = await decryptFn(currentVersion);

      // 4. Re-encrypt with current key & Atomic Isar Update
      final migratedRecord = await reEncryptAndUpdateFn(plainText, CryptoService.currentCryptoVersion);

      if (kDebugMode) {
        debugPrint('[KeyRotation] Migration successful for $recordUuid');
      }
      return migratedRecord;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[KeyRotation] CRITICAL ERROR during migration for $recordUuid: $e');
      }
      rethrow;
    } finally {
      migrationCompleter.complete();
      _migrationLocks.remove(recordUuid);
    }
  }
}

final keyRotationProvider = Provider((ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  return KeyRotationService(ref, crypto);
});
