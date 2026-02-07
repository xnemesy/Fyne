import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:cryptography/cryptography.dart';
import '../../models/transaction.dart';
import '../../services/crypto_service.dart';

class TransactionRepository {
  final Isar _isar;
  final CryptoService _crypto;
  final SecretKey _masterKey;

  TransactionRepository(this._isar, this._crypto, this._masterKey);

  /// PAGINATION: Loads encrypted items (FAST, no CPU block)
  Future<List<TransactionModel>> getEncryptedPage({
    required int page,
    int pageSize = 50,
  }) async {
    return _isar.transactionModels
        .where()
        .sortByBookingDateDesc()
        .offset(page * pageSize)
        .limit(pageSize)
        .findAll();
  }

  /// Single item decryption using Isolate
  Future<TransactionModel> decryptSingle(TransactionModel encrypted) async {
    final keyData = await _masterKey.extractBytes();
    
    return await compute(
      _decryptWorker,
      _DecryptionParams(
        model: encrypted,
        masterKeyBytes: keyData,
      ),
    );
  }

  /// Batch decryption for list pages (Isolate)
  Future<List<TransactionSummary>> decryptPageForList(
    List<TransactionModel> encryptedList,
  ) async {
    if (encryptedList.isEmpty) return [];
    
    final keyData = await _masterKey.extractBytes();

    return await compute(
      _decryptBatchWorker,
      _BatchDecryptionParams(
        models: encryptedList,
        masterKeyBytes: keyData,
      ),
    );
  }

  /// Fetch and decrypt by UUID
  Future<TransactionModel?> getByUuid(String uuid) async {
    final encrypted = await _isar.transactionModels
        .where()
        .uuidEqualTo(uuid)
        .findFirst();
        
    if (encrypted == null) return null;
    
    return decryptSingle(encrypted);
  }

  /// Save with Isolate encryption
  Future<void> save(TransactionModel tx, {String? rawAmount, String? rawDesc}) async {
    final keyData = await _masterKey.extractBytes();

    final encryptedModel = await compute(
      _encryptWorker,
      _EncryptionParams(
        model: tx,
        rawAmount: rawAmount ?? tx.amount?.toString() ?? "0.0",
        rawDescription: rawDesc ?? tx.description,
        masterKeyBytes: keyData,
      ),
    );

    await _isar.writeTxn(() async {
      await _isar.transactionModels.put(encryptedModel);
    });
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
  final List<int> masterKeyBytes;
  _EncryptionParams({
    required this.model, 
    required this.rawAmount, 
    this.rawDescription, 
    required this.masterKeyBytes
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
    encryptedCounterParty: params.model.counterParty != null ? await encrypt(params.model.counterParty!) : null,
    encryptedCategoryName: params.model.categoryName != null ? await encrypt(params.model.categoryName!) : null,
    createdAt: params.model.createdAt,
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
      return null;
    }
  }

  final amountStr = await decrypt(model.encryptedAmount);
  final amount = double.tryParse(amountStr ?? "0.0") ?? 0.0;
  
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
