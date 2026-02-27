import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/storage_provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/categorization_rule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crypto_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage;

  /// Fix Bug 3: CryptoService iniettato per validare i blob prima di put()
  final CryptoService _crypto;

  SyncService(this._storage, this._crypto);

  static const String _lastSyncKey = 'fyne_last_sync_timestamp';

  /// Esegue un ciclo completo di sincronizzazione (Pull poi Push).
  Future<void> performSync(Isar isar) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint("[Sync] Inizio sincronizzazione per ${user.uid}...");

    final lastSyncStr = await _storage.read(key: _lastSyncKey);
    final lastSyncAt = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.fromMillisecondsSinceEpoch(0);
    final currentSyncStartTime = DateTime.now();

    try {
      // 1. PULL: scarica le modifiche remote e valida i blob
      await _pullRemoteChanges(isar, user.uid, lastSyncAt);

      // 2. PUSH: invia le modifiche locali
      await _pushLocalChanges(isar, user.uid, lastSyncAt);

      // 3. Aggiorna timestamp ultimo sync
      await _storage.write(
          key: _lastSyncKey, value: currentSyncStartTime.toIso8601String());
      // Bug C: .update() crashava con [not-found] se il documento users/{uid}
      // non esisteva ancora (utente nuovo o doc mai inizializzato).
      // .set(merge: true) crea il documento se assente, aggiorna solo lastSync se presente.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({'lastSync': currentSyncStartTime}, SetOptions(merge: true));

      debugPrint("[Sync] Sincronizzazione completata con successo.");
    } catch (e) {
      debugPrint("[Sync] Errore durante il sync: $e");
      rethrow;
    }
  }

  Future<void> _pullRemoteChanges(
      Isar isar, String uid, DateTime lastSyncAt) async {
    final collections = [
      'transactions',
      'accounts',
      'budgets',
      'categorization_rules'
    ];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .where('updated_at', isGreaterThan: lastSyncAt.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) continue;

      debugPrint(
          "[Sync] Ricevute ${snapshot.docs.length} modifiche remote per $collection.");

      // Fix Bug 3: validazione HMAC/decrypt fuori dalla transazione Isar
      final validDocs = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isValid = await _validateBlob(collection, data);
        if (isValid) {
          validDocs.add(data);
        } else {
          debugPrint(
              "[Sync] ⚠️ Blob corrotto o HMAC invalido per ${collection}/${doc.id} — skippato.");
        }
      }

      if (validDocs.isEmpty) continue;

      // Scrivi su Isar solo i record che hanno superato la validazione
      await isar.writeTxn(() async {
        for (final data in validDocs) {
          await _applyRemoteChange(isar, collection, data);
        }
      });
    }
  }

  /// Fix Bug 3: tenta un decrypt di test su un campo campione per verificare
  /// l'integrità HMAC prima di persistere il blob su Isar.
  /// Ritorna true se il blob è integro, false se corrotto/manomesso.
  Future<bool> _validateBlob(
      String collection, Map<String, dynamic> data) async {
    try {
      switch (collection) {
        case 'accounts':
          final encName =
              data['encrypted_name'] ?? data['encryptedName'] ?? '';
          if (encName.isEmpty) return false;
          // Decrypt-test: verifica HMAC senza usare il risultato
          await _crypto.decrypt(
            encName,
            scope: EncryptionScope.database,
            version: data['encryption_version'] ?? 1,
            type: 'account_name',
          );

        case 'transactions':
          final encAmount =
              data['encrypted_amount'] ?? data['encryptedAmount'] ?? '';
          if (encAmount.isEmpty) return false;
          await _crypto.decrypt(
            encAmount,
            scope: EncryptionScope.database,
            version: data['encryption_version'] ?? 1,
            type: 'transaction_amount',
          );

        case 'budgets':
          // Budget non ha campi critici, verifica updated_at è sufficiente
          if (data['updated_at'] == null) return false;

        case 'categorization_rules':
          // Le regole sono in chiaro (keyword matching, no dati sensibili)
          if (data['uuid'] == null) return false;
      }
      return true;
    } catch (e) {
      // DecryptionException o HmacError = blob invalido
      debugPrint("[Sync] Decrypt-test fallito per $collection: $e");
      return false;
    }
  }

  Future<void> _applyRemoteChange(
      Isar isar, String collection, Map<String, dynamic> data) async {
    final remoteUpdatedAt = DateTime.parse(data['updated_at']);

    switch (collection) {
      case 'transactions':
        final remoteModel = TransactionModel.fromJson(data);
        final localModel = await isar.transactionModels
            .where()
            .uuidEqualTo(remoteModel.uuid)
            .findFirst();
        if (localModel == null ||
            remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.transactionModels.put(remoteModel);
        }

      case 'accounts':
        final remoteModel = Account.fromJson(data);
        final localModel = await isar.accounts
            .where()
            .idEqualTo(remoteModel.id)
            .findFirst();
        if (localModel == null ||
            remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.accounts.put(remoteModel);
        }

      case 'budgets':
        final remoteModel = Budget.fromJson(data);
        final localModel =
            await isar.budgets.where().idEqualTo(remoteModel.id).findFirst();
        if (localModel == null ||
            remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.budgets.put(remoteModel);
        }

      case 'categorization_rules':
        final remoteModel = CategorizationRule.fromJson(data);
        final localModel = await isar.categorizationRules
            .where()
            .uuidEqualTo(remoteModel.uuid)
            .findFirst();
        if (localModel == null ||
            remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.categorizationRules.put(remoteModel);
        }
    }
  }

  Future<void> _pushLocalChanges(
      Isar isar, String uid, DateTime lastSyncAt) async {
    int txOk = 0, txFail = 0;
    int accOk = 0, accFail = 0;
    int budOk = 0, budFail = 0;
    int ruleOk = 0, ruleFail = 0;

    // 1. Transactions
    final localTxs = await isar.transactionModels
        .where()
        .updatedAtGreaterThan(lastSyncAt)
        .findAll();
    for (final tx in localTxs) {
      try {
        debugPrint("[Sync] ⬆️ Upload transactions/${tx.uuid}");
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(tx.uuid)
            .set(tx.toJson());
        debugPrint("[Sync] ✅ transactions/${tx.uuid} confermata");
        txOk++;
      } catch (e) {
        debugPrint("[Sync] ❌ transactions/${tx.uuid} fallita: $e");
        txFail++;
      }
    }

    // 2. Accounts
    final localAccounts =
        await isar.accounts.where().updatedAtGreaterThan(lastSyncAt).findAll();
    for (final acc in localAccounts) {
      try {
        debugPrint("[Sync] ⬆️ Upload accounts/${acc.id}");
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('accounts')
            .doc(acc.id)
            .set(acc.toJson());
        debugPrint("[Sync] ✅ accounts/${acc.id} confermato");
        accOk++;
      } catch (e) {
        debugPrint("[Sync] ❌ accounts/${acc.id} fallito: $e");
        accFail++;
      }
    }

    // 3. Budgets
    final localBudgets =
        await isar.budgets.where().updatedAtGreaterThan(lastSyncAt).findAll();
    for (final b in localBudgets) {
      try {
        debugPrint("[Sync] ⬆️ Upload budgets/${b.id}");
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(b.id)
            .set(b.toJson());
        debugPrint("[Sync] ✅ budgets/${b.id} confermato");
        budOk++;
      } catch (e) {
        debugPrint("[Sync] ❌ budgets/${b.id} fallito: $e");
        budFail++;
      }
    }

    // 4. Categorization Rules
    final localRules = await isar.categorizationRules
        .where()
        .updatedAtGreaterThan(lastSyncAt)
        .findAll();
    for (final r in localRules) {
      try {
        debugPrint("[Sync] ⬆️ Upload categorization_rules/${r.uuid}");
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('categorization_rules')
            .doc(r.uuid)
            .set(r.toJson());
        debugPrint("[Sync] ✅ categorization_rules/${r.uuid} confermata");
        ruleOk++;
      } catch (e) {
        debugPrint("[Sync] ❌ categorization_rules/${r.uuid} fallita: $e");
        ruleFail++;
      }
    }

    // Riepilogo finale per verifica backup
    final totalOk = txOk + accOk + budOk + ruleOk;
    final totalFail = txFail + accFail + budFail + ruleFail;
    if (totalOk > 0 || totalFail > 0) {
      debugPrint(
        "[Sync] Push completato: $txOk tx, $accOk conti, $budOk budget, $ruleOk regole"
        "${totalFail > 0 ? ' | ⚠️ Falliti: $txFail tx, $accFail conti, $budFail budget, $ruleFail regole' : ''}",
      );
    }
    // Se almeno un'entità ha fallito il push, propaga l'errore
    // così SyncNotifier setta error e l'UI può mostrare la notifica
    if (totalFail > 0) {
      throw Exception(
          "[Sync] $totalFail entità non sincronizzate. Verranno ritentate al prossimo sync.");
    }
  }
}

/// Fix Bug 3: SyncService ora riceve CryptoService come dipendenza
final syncServiceProvider = Provider((ref) {
  final storage = ref.watch(secureStorageProvider);
  final crypto = ref.watch(cryptoServiceProvider);
  return SyncService(storage, crypto);
});
