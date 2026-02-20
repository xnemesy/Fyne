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
import '../providers/isar_provider.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage;

  SyncService(this._storage);

  static const String _lastSyncKey = 'fyne_last_sync_timestamp';

  /// Esegue un ciclo completo di sincronizzazione (Pull poi Push).
  Future<void> performSync(Isar isar) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint("[Sync] Inizio sincronizzazione per ${user.uid}...");

    final lastSyncStr = await _storage.read(key: _lastSyncKey);
    final lastSyncAt = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.fromMillisecondsSinceEpoch(0);
    final currentSyncStartTime = DateTime.now();

    try {
      // 1. PULL (Remote -> Local)
      await _pullRemoteChanges(isar, user.uid, lastSyncAt);

      // 2. PUSH (Local -> Remote)
      await _pushLocalChanges(isar, user.uid, lastSyncAt);

      // 3. Update Last Sync Timestamp
      await _storage.write(key: _lastSyncKey, value: currentSyncStartTime.toIso8601String());
      await _firestore.collection('users').doc(user.uid).update({
        'lastSync': currentSyncStartTime,
      });

      debugPrint("[Sync] Sincronizzazione completata con successo.");
    } catch (e) {
      debugPrint("[Sync] Errore durante il sync: $e");
      rethrow;
    }
  }

  Future<void> _pullRemoteChanges(Isar isar, String uid, DateTime lastSyncAt) async {
    final collections = ['transactions', 'accounts', 'budgets', 'categorization_rules'];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .where('updated_at', isGreaterThan: lastSyncAt.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) continue;

      debugPrint("[Sync] Ricevute ${snapshot.docs.length} modifiche remote per $collection.");

      await isar.writeTxn(() async {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          await _applyRemoteChange(isar, collection, data);
        }
      });
    }
  }

  Future<void> _applyRemoteChange(Isar isar, String collection, Map<String, dynamic> data) async {
    final remoteUpdatedAt = DateTime.parse(data['updated_at']);

    switch (collection) {
      case 'transactions':
        final remoteModel = TransactionModel.fromJson(data);
        final localModel = await isar.transactionModels.where().uuidEqualTo(remoteModel.uuid).findFirst();
        if (localModel == null || remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.transactionModels.put(remoteModel);
        }
        break;
      case 'accounts':
        final remoteModel = Account.fromJson(data);
        final localModel = await isar.accounts.where().idEqualTo(remoteModel.id).findFirst();
        if (localModel == null || remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.accounts.put(remoteModel);
        }
        break;
      case 'budgets':
        final remoteModel = Budget.fromJson(data);
        final localModel = await isar.budgets.where().idEqualTo(remoteModel.id).findFirst();
        if (localModel == null || remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.budgets.put(remoteModel);
        }
        break;
      case 'categorization_rules':
        final remoteModel = CategorizationRule.fromJson(data);
        final localModel = await isar.categorizationRules.where().uuidEqualTo(remoteModel.uuid).findFirst();
        if (localModel == null || remoteUpdatedAt.isAfter(localModel.updatedAt)) {
          await isar.categorizationRules.put(remoteModel);
        }
        break;
    }
  }

  Future<void> _pushLocalChanges(Isar isar, String uid, DateTime lastSyncAt) async {
    // 1. Transactions
    final localTxs = await isar.transactionModels
        .where()
        .updatedAtGreaterThan(lastSyncAt)
        .findAll();
    for (final tx in localTxs) {
      await _firestore.collection('users').doc(uid).collection('transactions').doc(tx.uuid).set(tx.toJson());
    }

    // 2. Accounts
    final localAccounts = await isar.accounts
        .where()
        .updatedAtGreaterThan(lastSyncAt)
        .findAll();
    for (final acc in localAccounts) {
      await _firestore.collection('users').doc(uid).collection('accounts').doc(acc.id).set(acc.toJson());
    }

    // 3. Budgets
    final localBudgets = await isar.budgets
        .where()
        .updatedAtGreaterThan(lastSyncAt)
        .findAll();
    for (final b in localBudgets) {
      await _firestore.collection('users').doc(uid).collection('budgets').doc(b.id).set(b.toJson());
    }

    // 4. Categorization Rules
    final localRules = await isar.categorizationRules
        .where()
        .updatedAtGreaterThan(lastSyncAt)
        .findAll();
    for (final r in localRules) {
      await _firestore.collection('users').doc(uid).collection('categorization_rules').doc(r.uuid).set(r.toJson());
    }
    
    if (localTxs.isNotEmpty || localAccounts.isNotEmpty || localBudgets.isNotEmpty || localRules.isNotEmpty) {
      debugPrint("[Sync] Inviate modifiche locali al server.");
    }
  }
}

final syncServiceProvider = Provider((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SyncService(storage);
});
