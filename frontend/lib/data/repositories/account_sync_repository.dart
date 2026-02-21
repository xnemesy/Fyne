import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/isar_provider.dart';
import '../../providers/master_key_provider.dart';
import '../../services/api_service.dart';
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

  Future<CreateAccountResult> createLocalFirst(
      CreateAccountCommand command) async {
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
      providerId:
          command.providerId?.isEmpty == true ? null : command.providerId,
      group: command.group,
      updatedAt: now,
      encryptionVersion: CryptoService.currentCryptoVersion,
      syncStatus: AccountSyncStatus.pendingCreate,
      remoteError: null,
    );

    await isar.writeTxn(() async {
      await isar.accounts.put(local);
    });

    unawaited(syncPendingCreates());

    return CreateAccountResult(
      localId: tempId,
      syncStatus: AccountSyncStatus.pendingCreate,
    );
  }

  Future<void> syncPendingCreates() async {
    final isar = await _ref.read(isarProvider.future);
    final allAccounts =
        await isar.accounts.where().isDeletedEqualTo(false).findAll();
    final pending = allAccounts
        .where(
          (a) =>
              a.syncStatus == AccountSyncStatus.pendingCreate ||
              a.syncStatus == AccountSyncStatus.failedCreate,
        )
        .toList();

    if (pending.isEmpty) return;

    for (final account in pending) {
      await _syncSingleAccount(account);
    }
  }

  Future<void> promoteTempIdToServerId(String tempId, String serverId) async {
    if (tempId == serverId) return;
    final isar = await _ref.read(isarProvider.future);

    await isar.writeTxn(() async {
      final existing =
          await isar.accounts.where().idEqualTo(tempId).findFirst();
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
      // Rimosso: await isar.accounts.delete(existing.isarId); dato che promoted ha lo stesso isarId e si sovrascrive.

      final linkedTransactions = await isar.transactionModels
          .where()
          .accountIdEqualTo(tempId)
          .findAll();

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

  Future<void> _syncSingleAccount(Account account) async {
    final api = _ref.read(apiServiceProvider);
    final isar = await _ref.read(isarProvider.future);

    try {
      debugPrint('🔐 [ACCOUNT_SYNC] Remote create start id=${account.id}');
      final response = await api.post('/api/accounts', data: {
        'encrypted_name': account.encryptedName,
        'encrypted_balance': account.encryptedBalance,
        'currency': account.currency,
        'type': account.type.name,
        'provider_id': account.providerId,
        'group_name': account.group,
      });

      final data = response.data;
      final remoteId =
          data is Map<String, dynamic> ? data['id'] as String? : null;

      if (remoteId != null && remoteId.isNotEmpty && remoteId != account.id) {
        await promoteTempIdToServerId(account.id, remoteId);
      } else {
        await isar.writeTxn(() async {
          final existing =
              await isar.accounts.where().idEqualTo(account.id).findFirst();
          if (existing == null) return;
          final synced = Account(
            id: existing.id,
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
          await isar.accounts.put(synced);
        });
      }

      debugPrint(
          '🔐 [ACCOUNT_SYNC] Remote create success id=${account.id} remoteId=${remoteId ?? account.id}');
    } catch (e) {
      debugPrint(
          '🔐 [ACCOUNT_SYNC] Remote create failed id=${account.id} error=$e');
      await isar.writeTxn(() async {
        final existing =
            await isar.accounts.where().idEqualTo(account.id).findFirst();
        if (existing == null) return;
        final failed = Account(
          id: existing.id,
          encryptedName: existing.encryptedName,
          encryptedBalance: existing.encryptedBalance,
          currency: existing.currency,
          type: existing.type,
          providerId: existing.providerId,
          group: existing.group,
          updatedAt: DateTime.now(),
          isDeleted: existing.isDeleted,
          encryptionVersion: existing.encryptionVersion,
          syncStatus: AccountSyncStatus.failedCreate,
          remoteError: e.toString(),
        )..isarId = existing.isarId;
        await isar.accounts.put(failed);
      });
    }
  }
}

double _normalizeBalance(String rawValue) {
  final normalized = rawValue.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0.0;
}
