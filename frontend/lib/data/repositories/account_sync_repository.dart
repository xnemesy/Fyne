import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/isar_provider.dart';
import '../../providers/master_key_provider.dart';
import '../../services/crypto_service.dart';

class CreateAccountCommand {
  final String name;
  final String balance;
  final AccountType type;
  final String group;
  final String? providerId;
  final String currency;

  const CreateAccountCommand({
    required this.name,
    required this.balance,
    required this.type,
    required this.group,
    this.providerId,
    this.currency = 'EUR',
  });
}

class CreateAccountResult {
  final String localId;
  final String? remoteId;
  final AccountSyncStatus syncStatus;

  const CreateAccountResult({
    required this.localId,
    this.remoteId,
    required this.syncStatus,
  });
}

class AccountSyncRepository {
  AccountSyncRepository(this._ref);

  final Ref _ref;
  static const Uuid _uuid = Uuid();

  // Fix Bug 3: usa Firestore direttamente invece di ApiService legacy
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CreateAccountResult> createLocalFirst(CreateAccountCommand command) async {
    final masterKey = _ref.read(masterKeyProvider);
    final crypto = _ref.read(cryptoServiceProvider);
    if (masterKey == null || !crypto.isUnlocked) {
      throw StateError('VaultNotReady');
    }

    final isar = await _ref.read(isarProvider.future);
    final name = command.name.trim();
    final balance = await compute(_normalizeBalance, command.balance);
    final tempId = 'tmp_${_uuid.v4()}';
    final now = DateTime.now();

    // Il payload è già cifrato con AES-256-GCM + HMAC da CryptoService
    final encryptedName = await crypto.encrypt(
      name,
      scope: EncryptionScope.database,
      type: 'account_name',
    );
    final encryptedBalance = await crypto.encrypt(
      balance.toStringAsFixed(2),
      scope: EncryptionScope.database,
      type: 'account_balance',
    );

    final local = Account(
      id: tempId,
      encryptedName: encryptedName,
      encryptedBalance: encryptedBalance,
      currency: command.currency,
      type: command.type,
      providerId: command.providerId?.isEmpty == true ? null : command.providerId,
      group: command.group,
      updatedAt: now,
      encryptionVersion: CryptoService.currentCryptoVersion,
      syncStatus: AccountSyncStatus.pendingCreate,
      remoteError: null,
    );

    await isar.writeTxn(() async {
      await isar.accounts.put(local);
    });

    debugPrint('🔐 [ACCOUNT_SYNC] Conto salvato localmente id=$tempId — sync Firestore in background');
    unawaited(syncPendingCreates());

    return CreateAccountResult(
      localId: tempId,
      syncStatus: AccountSyncStatus.pendingCreate,
    );
  }

  Future<void> syncPendingCreates() async {
    if (!_ref.mounted) return;
    final isar = await _ref.read(isarProvider.future);
    if (!_ref.mounted) return;
    final allAccounts = await isar.accounts.where().isDeletedEqualTo(false).findAll();
    final pending = allAccounts
        .where(
          (a) =>
              a.syncStatus == AccountSyncStatus.pendingCreate ||
              a.syncStatus == AccountSyncStatus.failedCreate,
        )
        .toList();

    if (pending.isEmpty) return;
    debugPrint('🔐 [ACCOUNT_SYNC] ${pending.length} conti in attesa di sync Firestore');

    for (final account in pending) {
      // Passa isar già risolto: evita _ref.read() post-await in _syncSingleAccount
      await _syncSingleAccount(account, isar: isar);
    }
  }

  Future<void> promoteTempIdToServerId(
    String tempId,
    String serverId, {
    required Isar isar,
  }) async {
    if (tempId == serverId) return;

    await isar.writeTxn(() async {
      final existing = await isar.accounts.where().idEqualTo(tempId).findFirst();
      if (existing == null) return;

      final promoted = Account(
        id: serverId,
        encryptedName: existing.encryptedName,
        encryptedBalance: existing.encryptedBalance,
        currency: existing.currency,
        type: existing.type,
        providerId: existing.providerId,
        group: existing.group,
        updatedAt: DateTime.now(),
        isDeleted: existing.isDeleted,
        encryptionVersion: existing.encryptionVersion,
        syncStatus: AccountSyncStatus.synced,
        remoteError: null,
      )..isarId = existing.isarId;

      await isar.accounts.put(promoted);

      // Aggiorna le transazioni legate al tempId
      final linkedTransactions =
          await isar.transactionModels.where().accountIdEqualTo(tempId).findAll();

      for (final tx in linkedTransactions) {
        final updatedTx = TransactionModel(
          id: tx.id,
          uuid: tx.uuid,
          accountId: serverId,
          bookingDate: tx.bookingDate,
          currency: tx.currency,
          encryptedAmount: tx.encryptedAmount,
          encryptedDescription: tx.encryptedDescription,
          encryptedCounterParty: tx.encryptedCounterParty,
          encryptedCategoryName: tx.encryptedCategoryName,
          categoryUuid: tx.categoryUuid,
          createdAt: tx.createdAt,
          updatedAt: DateTime.now(),
          isDeleted: tx.isDeleted,
          encryptionVersion: tx.encryptionVersion,
        );
        await isar.transactionModels.put(updatedTx);
      }
    });
  }

  /// Upload del blob cifrato su Firestore.
  /// Riceve [isar] già risolto da [syncPendingCreates] per evitare _ref.read() post-await.
  /// Usa l'UUID reale (senza prefisso tmp_) come doc ID su Firestore e promuove l'ID locale.
  Future<void> _syncSingleAccount(Account account, {required Isar isar}) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      debugPrint('🔐 [ACCOUNT_SYNC] ⚠️ Utente non autenticato — upload rimandato id=${account.id}');
      return;
    }

    // Il remote ID è l'UUID reale: rimuove il prefisso tmp_ se presente
    final realId = account.id.startsWith('tmp_') ? account.id.substring(4) : account.id;

    try {
      debugPrint('🔐 [ACCOUNT_SYNC] Upload Firestore start id=${account.id} → remoteId=$realId');

      // Payload con ID reale e syncStatus=synced (il record è in Firestore → è synced)
      final payload = account.toJson()
        ..['id'] = realId
        ..['sync_status'] = AccountSyncStatus.synced.name
        ..['remote_error'] = null;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(realId)
          .set(payload);

      debugPrint('🔐 [ACCOUNT_SYNC] ✅ Firestore upload OK remoteId=$realId');

      // Promuove il tmp_ ID al remote ID in Isar (aggiorna anche le transazioni collegate)
      // isar è già risolto prima di qualsiasi await: nessun ref.read() post-await
      await promoteTempIdToServerId(account.id, realId, isar: isar);
    } catch (e) {
      debugPrint('🔐 [ACCOUNT_SYNC] ❌ Firestore upload FAILED id=${account.id} error=$e');
      // Cerca per l'ID originale (la promozione non è avvenuta in caso di errore al set)
      await isar.writeTxn(() async {
        final existing = await isar.accounts.where().idEqualTo(account.id).findFirst();
        if (existing == null) return;
        await isar.accounts.put(Account(
          id: existing.id,
          encryptedName: existing.encryptedName,
          encryptedBalance: existing.encryptedBalance,
          currency: existing.currency,
          type: existing.type,
          providerId: existing.providerId,
          group: existing.group,
          updatedAt: existing.updatedAt,
          isDeleted: existing.isDeleted,
          encryptionVersion: existing.encryptionVersion,
          syncStatus: AccountSyncStatus.failedCreate,
          remoteError: e.toString(),
        )..isarId = existing.isarId);
      });
    }
  }
}

double _normalizeBalance(String rawValue) {
  final normalized = rawValue.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0.0;
}

