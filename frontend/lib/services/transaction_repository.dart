import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:cryptography/cryptography.dart';
import '../models/transaction.dart';
import 'crypto_service.dart';
import '../providers/isar_provider.dart';
import '../providers/master_key_provider.dart';

class TransactionRepository {
  final Isar isar;
  final CryptoService crypto;
  final SecretKey masterKey;

  TransactionRepository({
    required this.isar,
    required this.crypto,
    required this.masterKey,
  });

  /// Salva una transazione criptando i campi sensibili
  Future<void> save(TransactionModel transaction) async {
    final encDesc = await crypto.encrypt(transaction.decryptedDescription ?? '', masterKey);
    final encCP = await crypto.encrypt(transaction.decryptedCounterParty ?? '', masterKey);
    final encAmount = await crypto.encrypt(transaction.amount.toString(), masterKey);

    final encrypted = transaction.copyWith(
      encryptedDescription: encDesc,
      encryptedCounterParty: encCP,
      encryptedAmount: encAmount,
      // For privacy, we rely on encryptedAmount. 
      // Ideally 'amount' field should be cleared or ignored by Isar, 
      // but since 'amount' is ignored via @ignore in the model, it won't be persisted.
    );

    await isar.writeTxn(() async {
      await isar.transactionModels.put(encrypted);
    });
  }

  /// Recupera una transazione e decripta i campi
  Future<TransactionModel?> findById(int id) async {
    final raw = await isar.transactionModels.get(id);
    if (raw == null) return null;

    try {
      final decryptedDesc = await crypto.decrypt(raw.encryptedDescription ?? '', masterKey);
      final decryptedCP = raw.encryptedCounterParty != null 
          ? await crypto.decrypt(raw.encryptedCounterParty!, masterKey) 
          : null;
      
      double decryptedAmount = raw.amount;
      if (raw.encryptedAmount != null) {
         final amountStr = await crypto.decrypt(raw.encryptedAmount!, masterKey);
         decryptedAmount = double.tryParse(amountStr) ?? 0.0;
      }
      
      return raw.copyWith(
        decryptedDescription: decryptedDesc,
        decryptedCounterParty: decryptedCP,
        amount: decryptedAmount,
      );
    } catch (e) {
      // In case of decryption error, return raw or handle gracefully
      return raw;
    }
  }
  
  /// Recupera tutte le transazioni e le decripta in parallelo
  Future<List<TransactionModel>> getAll() async {
    final rawList = await isar.transactionModels.where().findAll();
    
    final futures = rawList.map((tx) async {
       try {
        final decryptedDesc = await crypto.decrypt(tx.encryptedDescription ?? '', masterKey);
        final decryptedCP = tx.encryptedCounterParty != null 
            ? await crypto.decrypt(tx.encryptedCounterParty!, masterKey) 
            : null;
            
        double decryptedAmount = tx.amount;
        if (tx.encryptedAmount != null) {
           final amountStr = await crypto.decrypt(tx.encryptedAmount!, masterKey);
           decryptedAmount = double.tryParse(amountStr) ?? 0.0;
        }
        
        return tx.copyWith(
          decryptedDescription: decryptedDesc,
          decryptedCounterParty: decryptedCP,
          amount: decryptedAmount,
        );
      } catch (e) {
        return tx;
      }
    });

    return Future.wait(futures);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository?>((ref) {
  final isar = ref.watch(isarProvider).value;
  final crypto = ref.watch(cryptoServiceProvider);
  final masterKey = ref.watch(masterKeyProvider);
  
  if (isar == null || masterKey == null) {
    return null;
  }

  return TransactionRepository(
    isar: isar,
    crypto: crypto,
    masterKey: masterKey,
  );
});
