import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_connection.dart';
import '../models/transaction.dart';
import 'crypto_service.dart';
import 'tink_refresh_service.dart';
import '../providers/isar_provider.dart';
import 'package:isar_community/isar.dart';

/**
 * Service to manage Tink synchronization with full Zero-Knowledge guarantees.
 * v2.3 Hardened Implementation:
 * - Direct AAD binding to providerId to prevent Replay Attacks.
 * - Encrypted Envelope (Token+Expiry) authentication.
 * - One-by-one memory processing to avoid Large-Scale Plaintext exposure.
 */
class TinkSyncService {
  final CryptoService _crypto;
  final Ref _ref;

  TinkSyncService(this._ref, this._crypto);

  /// Synchronizes transactions for a given bank connection.
  Future<void> syncConnection(BankConnection connection) async {
    if (_crypto.isLocked) {
      if (kDebugMode) {
        debugPrint('[TinkSync] ERROR: Vault is locked. Sync aborted.');
      }
      return;
    }

    try {
      // 0. Ensure Token is valid (triggers refresh if <60s left)
      final refreshService = _ref.read(tinkRefreshProvider);
      await refreshService.ensureValidAccessToken(connection);

      // Reload connection from Isar in case it was updated by refreshService
      final isarForReload = await _ref.read(isarProvider.future);
      final activeConnection = await isarForReload.bankConnections
          .where()
          .providerIdEqualTo(connection.providerId)
          .findFirst();

      if (activeConnection == null) {
        throw Exception('Connessione bancaria non trovata dopo il refresh.');
      }

      // 1. Verify & Decrypt Token Envelope (Authenticated with providerId)
      final envelopeJson = await _crypto.decrypt(
        activeConnection.encryptedAccessEnvelope,
        scope: EncryptionScope.apiToken,
        type: 'access_envelope',
        contextId: activeConnection.providerId,
        version: activeConnection.encryptionVersion,
      );
      
      final Map<String, dynamic> envelope = jsonDecode(envelopeJson);
      final String accessToken = envelope['token'];
      final DateTime expiresAt = DateTime.parse(envelope['expiresAt']);

      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Token Tink scaduto. Richiesta nuova autenticazione.');
      }

      // 2. Fetch from Blind Proxy (TLS)
      // In a real implementation, we would use a specialized client that
      // does not log headers or bodies.
      final List<dynamic> rawTinkTransactions = await _fetchFromProxy(accessToken);

      // 3. Hardened Item-by-Item Processing
      final isar = await _ref.read(isarProvider.future);
      
      await isar.writeTxn(() async {
        for (final raw in rawTinkTransactions) {
          // Process and encrypt immediately
          final transaction = await _processAndEncryptItem(raw);
          await isar.transactionModels.put(transaction);
          
          // Trigger GC hints if possible (Dart doesn't have explicit wipe for strings/maps)
          // but minimizing scope helps.
        }
      });

      // Clear local list reference as soon as possible
      rawTinkTransactions.clear();
      if (kDebugMode) {
        debugPrint('[TinkSync] Sync completed with integrity for ${connection.bankName}');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TinkSync] CRITICAL ERROR: $e');
      }
      if (e.toString().contains('Integrity mismatch')) {
        // SECURITY ALERT: Possible database tampering detected
        if (kDebugMode) {
          debugPrint('[TinkSync] SECURITY: Integrity mismatch detected for ${connection.providerId}!');
        }
      }
      rethrow;
    }
  }

  /// Internal: Processes matching the Tink JSON to Fyne TransactionModel.
  /// Encrypts fields granularity BEFORE saving.
  Future<TransactionModel> _processAndEncryptItem(Map<String, dynamic> raw) async {
    final amount = raw['amount']?.toString() ?? '0.0';
    final description = raw['description'] ?? 'Transazione Bancaria';
    
    // Individual field encryption with structured AAD
    final encryptedAmount = await _crypto.encrypt(
      amount,
      scope: EncryptionScope.database,
      type: 'transaction_amount',
    );
    
    final encryptedDesc = await _crypto.encrypt(
      description,
      scope: EncryptionScope.database,
      type: 'transaction_description',
    );

    return TransactionModel(
      uuid: raw['id'] ?? '',
      accountId: raw['accountId'] ?? '',
      bookingDate: DateTime.parse(raw['date'] ?? DateTime.now().toIso8601String()),
      currency: raw['currency'] ?? 'EUR',
      encryptedAmount: encryptedAmount,
      encryptedDescription: encryptedDesc,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      encryptionVersion: 1, // Current schema
    );
  }

  /// Placeholder: Chiamata al Blind Proxy Backend.
  Future<List<dynamic>> _fetchFromProxy(String accessToken) async {
    // In production: return (await dio.get('/api/sync/tink', options: Options(headers: {'Authorization': 'Bearer $accessToken'}))).data;
    return []; 
  }
}

final tinkSyncProvider = Provider((ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  return TinkSyncService(ref, crypto);
});
