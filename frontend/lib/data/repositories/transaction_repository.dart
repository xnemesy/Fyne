import 'dart:convert';
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
}

// === ISOLATE WORKERS & PARAMS ===

class _DecryptionParams {
  final TransactionModel model;
  final List<int> masterKeyBytes;
  _DecryptionParams({required this.model, required this.masterKeyBytes});
}

class _BatchDecryptionParams {
  final List<TransactionModel> models;
  final List<int> masterKeyBytes;
  _BatchDecryptionParams({required this.models, required this.masterKeyBytes});
}

class _EncryptionParams {
  final TransactionModel model;
  final String rawAmount;
  final String? rawDescription;
  final String? rawCounterParty;
  final String? rawCategoryName;
  final List<int> masterKeyBytes;
  final DateTime updatedAt;
  final bool isDeleted;
  _EncryptionParams({
    required this.model, 
    required this.rawAmount, 
    this.rawDescription, 
    this.rawCounterParty,
    this.rawCategoryName,
    required this.masterKeyBytes,
    required this.updatedAt,
    this.isDeleted = false,
  });
}

/// ASYNC Worker for Isolate Decryption
Future<TransactionModel> _decryptWorker(_DecryptionParams params) async {
  return await _decryptAsync(params.model, params.masterKeyBytes);
}

/// Batch Worker
Future<List<TransactionSummary>> _decryptBatchWorker(_BatchDecryptionParams params) async {
  final List<TransactionSummary> summaries = [];
  for (final m in params.models) {
    final decrypted = await _decryptAsync(m, params.masterKeyBytes);
    summaries.add(TransactionSummary(
      uuid: decrypted.uuid,
      amount: decrypted.amount ?? 0.0,
      bookingDate: decrypted.bookingDate,
      categoryName: decrypted.categoryName,
      categoryUuid: decrypted.categoryUuid,
      description: decrypted.description,
      counterParty: decrypted.counterParty,
      accountId: decrypted.accountId,
    ));
  }
  return summaries;
}

/// Encryption Worker
Future<TransactionModel> _encryptWorker(_EncryptionParams params) async {
  final algorithm = AesGcm.with256bits();
  final secretKey = SecretKey(params.masterKeyBytes);
  
  Future<String> encrypt(String text) async {
    final secretBox = await algorithm.encrypt(utf8.encode(text), secretKey: secretKey);
    return base64.encode(secretBox.concatenation());
  }

  return TransactionModel(
    uuid: params.model.uuid,
    accountId: params.model.accountId,
    bookingDate: params.model.bookingDate,
    currency: params.model.currency,
    encryptedAmount: await encrypt(params.rawAmount),
    encryptedDescription: params.rawDescription != null ? await encrypt(params.rawDescription!) : null,
    encryptedCounterParty: params.rawCounterParty != null ? await encrypt(params.rawCounterParty!) : null,
    encryptedCategoryName: params.rawCategoryName != null ? await encrypt(params.rawCategoryName!) : null,
    categoryUuid: params.model.categoryUuid,
    createdAt: params.model.createdAt,
    updatedAt: params.updatedAt,
    isDeleted: params.isDeleted,
  );
}

/// Helper for Isolate decryption
Future<TransactionModel> _decryptAsync(TransactionModel model, List<int> keyBytes) async {
  final algorithm = AesGcm.with256bits();
  final secretKey = SecretKey(keyBytes);

  Future<String?> decrypt(String? base64Data) async {
    if (base64Data == null) return null;
    try {
      final data = base64.decode(base64Data);
      final secretBox = SecretBox.fromConcatenation(
        data,
        nonceLength: algorithm.nonceLength,
        macLength: algorithm.macAlgorithm.macLength,
      );
      final clearText = await algorithm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clearText);
    } catch (e) {
      debugPrint('⚠️ Decryption failed for field: $e');
      return null;
    }
  }

  final amountStr = await decrypt(model.encryptedAmount);
  final amount = amountStr != null ? double.tryParse(amountStr) : null;
  
  final desc = await decrypt(model.encryptedDescription);
  final cp = await decrypt(model.encryptedCounterParty);
  final cat = await decrypt(model.encryptedCategoryName);

  return model.copyWithDecrypted(
    amount: amount,
    description: desc,
    counterParty: cp,
    categoryName: cat,
  );
}
