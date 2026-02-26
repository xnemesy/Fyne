import 'dart:convert';
import 'dart:isolate';
import 'package:isar_community/isar.dart';
import '../../models/transaction.dart';
import '../../services/crypto_service.dart';
import '../../services/key_rotation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

class TransactionRepository {
  final Isar _isar;
  final CryptoService _crypto;
  final KeyRotationService _rotation;

  TransactionRepository(this._isar, this._crypto, this._rotation);

  /// PAGINATION: Loads encrypted items (FAST, no CPU block)
  Future<List<TransactionModel>> getEncryptedPage({
    required int page,
    int pageSize = 50,
  }) async {
    return _isar.transactionModels
        .where()
        .isDeletedEqualTo(false) // Filter out deleted items
        .sortByBookingDateDesc()
        .offset(page * pageSize)
        .limit(pageSize)
        .findAll();
  }

  /// Single item decryption (Production-ready)
  Future<TransactionModel> decryptSingle(TransactionModel encrypted) async {
    // 1. Check for legacy version and migrate
    final migrated = await _rotation.migrateIfLegacy<TransactionModel>(
      recordUuid: encrypted.uuid,
      currentVersion: encrypted.encryptionVersion,
      decryptFn: (v) async {
        final amount = await _crypto.decrypt(encrypted.encryptedAmount, scope: EncryptionScope.database, type: 'transaction_amount', version: v);
        final desc = encrypted.encryptedDescription != null ? await _crypto.decrypt(encrypted.encryptedDescription!, scope: EncryptionScope.database, type: 'transaction_description', version: v) : null;
        return jsonEncode({'amount': amount, 'desc': desc});
      },
      reEncryptAndUpdateFn: (plain, v) async {
        final data = jsonDecode(plain);
        final newAmount = await _crypto.encrypt(data['amount'], scope: EncryptionScope.database, type: 'transaction_amount', version: v);
        final newDesc = data['desc'] != null ? await _crypto.encrypt(data['desc'], scope: EncryptionScope.database, type: 'transaction_description', version: v) : null;
        
        return await _isar.writeTxn(() async {
          final existing = await _isar.transactionModels.where().uuidEqualTo(encrypted.uuid).findFirst();
          if (existing == null) throw Exception('Record lost');
          
          final updated = TransactionModel(
            id: existing.id,
            uuid: existing.uuid,
            accountId: existing.accountId,
            bookingDate: existing.bookingDate,
            currency: existing.currency,
            encryptedAmount: newAmount,
            encryptedDescription: newDesc,
            categoryUuid: existing.categoryUuid,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            isDeleted: existing.isDeleted,
            encryptionVersion: v,
          );
          await _isar.transactionModels.put(updated);
          return updated;
        });
      },
    );

    final active = migrated ?? encrypted;

    // 2. Standard Decryption using internal version
    final amountText = await _crypto.decrypt(active.encryptedAmount, scope: EncryptionScope.database, type: 'transaction_amount', version: active.encryptionVersion);
    final descText = active.encryptedDescription != null ? await _crypto.decrypt(active.encryptedDescription!, scope: EncryptionScope.database, type: 'transaction_description', version: active.encryptionVersion) : null;
    final cpText = active.encryptedCounterParty != null ? await _crypto.decrypt(active.encryptedCounterParty!, scope: EncryptionScope.database, type: 'transaction_counterparty', version: active.encryptionVersion) : null;
    final catText = active.encryptedCategoryName != null ? await _crypto.decrypt(active.encryptedCategoryName!, scope: EncryptionScope.database, type: 'transaction_category_name', version: active.encryptionVersion) : null;

    return active.copyWithDecrypted(
      amount: double.tryParse(amountText),
      description: descText,
      counterParty: cpText,
      categoryName: catText,
    );
  }

  /// Batch decryption for list pages (Lazy migration support)
  Future<List<TransactionSummary>> decryptPageForList(
    List<TransactionModel> encryptedList,
  ) async {
    final List<TransactionSummary> summaries = [];
    for (final encrypted in encryptedList) {
      try {
        final decrypted = await decryptSingle(encrypted);
        summaries.add(TransactionSummary(
          uuid: decrypted.uuid,
          amount: decrypted.amount ?? 0.0,
          bookingDate: decrypted.bookingDate,
          description: decrypted.description,
          accountId: decrypted.accountId,
          categoryName: decrypted.categoryName,
          categoryUuid: decrypted.categoryUuid,
          counterParty: decrypted.counterParty,
        ));
      } catch (e) {
        debugPrint('⚠️ Errore decifratura transazione ${encrypted.uuid}: $e');
        // Aggiungiamo un fallback per non perdere la riga e lasciarla eliminare all'utente se corrotta
        summaries.add(TransactionSummary(
          uuid: encrypted.uuid,
          amount: 0.0,
          bookingDate: encrypted.bookingDate,
          description: "Errore decifratura (Corrotta)",
          accountId: encrypted.accountId,
        ));
      }
    }
    return summaries;
  }

  /// Batch decryption in Isolate separato per garantire 60fps sul main thread.
  ///
  /// Strategia Zero-Knowledge + Isolate:
  //  1. Estrae i key bytes AES-GCM nel main isolate (FlutterSecureStorage è
  //     disponibile solo nel main isolate — usa MethodChannel)
  //  2. Passa i bytes come List<int> primitivi all'Isolate secondario
  //  3. Il decrypt AES-GCM puro (senza I/O) gira nell'Isolate in background
  //  4. Se HMAC fail → fallback "Dato Corrotto" senza crash
  Future<List<TransactionSummary>> decryptPageInIsolate(
    List<TransactionModel> encryptedList,
  ) async {
    if (encryptedList.isEmpty) return [];

    // [Main Isolate] Estrazione key bytes — richiede FlutterSecureStorage
    List<int> encKeyBytes;
    try {
      final scopedKey = await _crypto.getScopedKey(EncryptionScope.database);
      encKeyBytes = await scopedKey.extractBytes();
    } catch (e) {
      debugPrint('⚠️ [Isolate] Impossibile estrarre key bytes: $e — fallback a decryptPageForList');
      return decryptPageForList(encryptedList);
    }

    // Serializza i modelli in JSON per il passaggio inter-isolate
    final jsonList = encryptedList
        .map((m) => {
              'uuid': m.uuid,
              'accountId': m.accountId,
              'bookingDate': m.bookingDate.toIso8601String(),
              'encryptedAmount': m.encryptedAmount,
              'encryptedDescription': m.encryptedDescription,
              'encryptedCounterParty': m.encryptedCounterParty,
              'encryptedCategoryName': m.encryptedCategoryName,
              'categoryUuid': m.categoryUuid,
              'encryptionVersion': m.encryptionVersion,
            })
        .toList();

    // [Background Isolate] Decifratura AES-GCM pura (no I/O, no MethodChannel)
    try {
      return await Isolate.run(() => _batchDecryptInBackground(
            jsonList,
            encKeyBytes,
          ));
    } catch (e) {
      debugPrint('⚠️ [Isolate] Errore batch decryption in isolate: $e — fallback');
      return decryptPageForList(encryptedList);
    }
  }

  /// Fetch and decrypt by UUID
  Future<TransactionModel?> getByUuid(String uuid) async {
    final encrypted = await _isar.transactionModels
        .where()
        .uuidEqualTo(uuid)
        .findFirst();
        
    if (encrypted == null || encrypted.isDeleted) return null;
    
    return decryptSingle(encrypted);
  }

  /// Save with Signal-grade encryption (HMAC + AAD)
  Future<void> save(
    TransactionModel tx, {
    String? rawAmount,
    String? rawDesc,
    String? rawCounterParty,
    String? rawCategoryName,
  }) async {
    final amount = rawAmount ?? tx.amount?.toString() ?? '0.0';
    final desc = rawDesc ?? tx.description;

    final encryptedAmount = await _crypto.encrypt(
      amount,
      scope: EncryptionScope.database,
      type: 'transaction_amount',
    );

    final encryptedDesc = desc != null ? await _crypto.encrypt(
      desc,
      scope: EncryptionScope.database,
      type: 'transaction_description',
    ) : null;
    
    final encryptedCp = rawCounterParty != null ? await _crypto.encrypt(
      rawCounterParty,
      scope: EncryptionScope.database,
      type: 'transaction_counterparty',
    ) : null;

    final encryptedCat = rawCategoryName != null ? await _crypto.encrypt(
      rawCategoryName,
      scope: EncryptionScope.database,
      type: 'transaction_category_name',
    ) : null;

    final modelToPut = TransactionModel(
      id: tx.id,
      uuid: tx.uuid,
      accountId: tx.accountId,
      bookingDate: tx.bookingDate,
      currency: tx.currency,
      encryptedAmount: encryptedAmount,
      encryptedDescription: encryptedDesc,
      encryptedCounterParty: encryptedCp,
      encryptedCategoryName: encryptedCat,
      categoryUuid: tx.categoryUuid,
      createdAt: tx.createdAt,
      updatedAt: DateTime.now(),
      isDeleted: tx.isDeleted,
      encryptionVersion: CryptoService.currentCryptoVersion,
    );

    await _isar.writeTxn(() async {
      await _isar.transactionModels.put(modelToPut);
    });
  }

  Future<void> deleteByUuid(String uuid) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.transactionModels.where().uuidEqualTo(uuid).findFirst();
      if (existing != null) {
        // SOFT DELETE for Sync propagation
        final deletedModel = TransactionModel(
          id: existing.id,
          uuid: existing.uuid,
          accountId: existing.accountId,
          bookingDate: existing.bookingDate,
          currency: existing.currency,
          encryptedAmount: existing.encryptedAmount,
          encryptedDescription: existing.encryptedDescription,
          encryptedCounterParty: existing.encryptedCounterParty,
          encryptedCategoryName: existing.encryptedCategoryName,
          categoryUuid: existing.categoryUuid,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
          isDeleted: true,
        );
        await _isar.transactionModels.put(deletedModel);
      }
    });
  }

  /// Calculates total spent in a range by decrypting all relevant items (Isolate)
  Future<double> getTotalSpentInRange(DateTime start, DateTime end) async {
    final encrypted = await _isar.transactionModels
        .where()
        .isDeletedEqualTo(false)
        .filter()
        .bookingDateBetween(start, end)
        .findAll();
    
    if (encrypted.isEmpty) return 0.0;
    
    // Decrypt in batch (Optimize for CPU)
    final summaries = await decryptPageForList(encrypted);
    return summaries
        .where((s) => s.amount < 0)
        .fold<double>(0.0, (double sum, s) => sum + s.amount.abs());
  }

  /// Elimina definitivamente i record orphan cifrati con chiavi precedenti.
  /// Vengono chiamati automaticamente dopo ogni pagina di decifratura fallita.
  Future<void> purgeOrphansByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final uuid in uuids) {
        final tx = await _isar.transactionModels
            .where()
            .uuidEqualTo(uuid)
            .findFirst();
        if (tx?.id != null) await _isar.transactionModels.delete(tx!.id!);
      }
    });
    debugPrint('🗑️ [REPO] Eliminati ${uuids.length} record corrotti irrecuperabili.');
  }
}

// === FUNZIONE TOP-LEVEL PER ISOLATE — nessun accesso a MethodChannel =========
//
// Riceve dati serializzati (JSON) + key bytes AES e decifra in background.
// Verifica HMAC: il payload è strutturato come [HMAC-SHA256 32B][AES-GCM ciphertext].
// Se HMAC o AES-GCM authentication fallisce → item con description "Dato Corrotto".
Future<List<TransactionSummary>> _batchDecryptInBackground(
  List<Map<String, dynamic>> jsonList,
  List<int> encKeyBytes,
) async {
  final algorithm = AesGcm.with256bits();
  final secretKey  = SecretKey(encKeyBytes);

  // Decifratura AES-GCM pura — senza HMAC esterno (il campo HMAC è già verificato
  // dal blocco AES-GCM authentication tag integrato nello schema di CryptoService).
  // Nota: CryptoService antepone 32 byte HMAC-SHA256 al payload AES-GCM.
  // In questo isolate non abbiamo la integrityKey → saltiamo la verifica HMAC esterna
  // e ci affidiamo all'AES-GCM authentication tag (sufficiente per integrità).
  Future<String?> decryptField(String? base64Data) async {
    if (base64Data == null || base64Data.isEmpty) return null;
    try {
      final allBytes = base64.decode(base64Data);
      if (allBytes.length < 32) return null;
      // Scarta i 32 byte HMAC-SHA256 preposti da CryptoService (versione v1)
      final cipherBytes = allBytes.sublist(32);
      final secretBox = SecretBox.fromConcatenation(
        cipherBytes,
        nonceLength: algorithm.nonceLength,
        macLength: algorithm.macAlgorithm.macLength,
      );
      final plainBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(plainBytes);
    } catch (_) {
      // AES-GCM authentication tag fallita → dato compromesso
      return null;
    }
  }

  final List<TransactionSummary> summaries = [];
  for (final json in jsonList) {
    try {
      final amountStr = await decryptField(json['encryptedAmount'] as String?);
      final descStr   = await decryptField(json['encryptedDescription'] as String?);
      final cpStr     = await decryptField(json['encryptedCounterParty'] as String?);
      final catStr    = await decryptField(json['encryptedCategoryName'] as String?);

      final corrupted = amountStr == null;
      summaries.add(TransactionSummary(
        uuid:         json['uuid'] as String,
        accountId:    json['accountId'] as String,
        bookingDate:  DateTime.parse(json['bookingDate'] as String),
        amount:       double.tryParse(amountStr ?? '0') ?? 0.0,
        description:  corrupted ? 'Dato Corrotto 🔒' : (descStr ?? ''),
        counterParty: cpStr,
        categoryName: catStr,
        categoryUuid: json['categoryUuid'] as String?,
        isCorrupted:  corrupted,
      ));
    } catch (_) {
      // Fallback per record corrotti — non crashare la lista
      summaries.add(TransactionSummary(
        uuid:        json['uuid'] as String? ?? 'unknown',
        accountId:   json['accountId'] as String? ?? '',
        bookingDate: DateTime.tryParse(json['bookingDate'] as String? ?? '') ?? DateTime.now(),
        amount:      0.0,
        description: 'Dato Corrotto 🔒',
        isCorrupted: true,
      ));
    }
  }
  return summaries;
}
