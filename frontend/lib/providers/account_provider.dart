import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../models/account.dart';
import '../services/crypto_service.dart';
import 'isar_provider.dart';
import '../services/key_rotation_service.dart';
import '../data/repositories/account_sync_repository.dart';
import 'account_sync_provider.dart';
import 'dart:convert';

class AccountNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final isar = await ref.watch(isarProvider.future);

    // Watch for changes in Isar to keep UI reactive
    final stream = isar.accounts
        .where()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);

    // We handle the stream by updating the state when Isar changes
    stream.listen((accounts) async {
      await _processAccounts(accounts);
      state = AsyncData(accounts);
    });

    return _fetchAndProcessAccounts(isar);
  }

  Future<List<Account>> _fetchAndProcessAccounts(Isar isar) async {
    final accounts =
        await isar.accounts.where().isDeletedEqualTo(false).findAll();
    await _processAccounts(accounts);
    return accounts;
  }

  Future<void> _processAccounts(List<Account> accounts) async {
    final crypto = ref.read(cryptoServiceProvider);
    final rotation = ref.read(keyRotationProvider);
    final isar = await ref.read(isarProvider.future);

    for (var i = 0; i < accounts.length; i++) {
      final account = accounts[i];

      // 1. Lazy Migration
      final migrated = await rotation.migrateIfLegacy<Account>(
        recordUuid: account.id,
        currentVersion: account.encryptionVersion,
        decryptFn: (v) async {
          final name = await crypto.decrypt(account.encryptedName,
              scope: EncryptionScope.database,
              type: 'account_name',
              version: v);
          final balance = await crypto.decrypt(account.encryptedBalance,
              scope: EncryptionScope.database,
              type: 'account_balance',
              version: v);
          return jsonEncode({'name': name, 'balance': balance});
        },
        reEncryptAndUpdateFn: (plain, v) async {
          final data = jsonDecode(plain);
          final newName = await crypto.encrypt(data['name'],
              scope: EncryptionScope.database,
              type: 'account_name',
              version: v);
          final newBalance = await crypto.encrypt(data['balance'],
              scope: EncryptionScope.database,
              type: 'account_balance',
              version: v);

          return await isar.writeTxn(() async {
            final existing =
                await isar.accounts.where().idEqualTo(account.id).findFirst();
            if (existing == null) throw Exception('Record lost');

            final updated = Account(
              id: existing.id,
              encryptedName: newName,
              encryptedBalance: newBalance,
              currency: existing.currency,
              type: existing.type,
              providerId: existing.providerId,
              group: existing.group,
              updatedAt: DateTime.now(),
              isDeleted: existing.isDeleted,
              encryptionVersion: v,
            )..isarId = existing.isarId;
            await isar.accounts.put(updated);
            return updated;
          });
        },
      );

      final active = migrated ?? account;
      if (migrated != null) accounts[i] = migrated;

      // 2. Standard Decryption
      try {
        active.decryptedName = await crypto.decrypt(active.encryptedName,
            scope: EncryptionScope.database,
            type: 'account_name',
            version: active.encryptionVersion);
        active.decryptedBalance = await crypto.decrypt(active.encryptedBalance,
            scope: EncryptionScope.database,
            type: 'account_balance',
            version: active.encryptionVersion);
      } catch (e) {
        active.decryptedName =
            "Account Criptato [v${active.encryptionVersion}]";
        active.decryptedBalance = "0.00";
      }
    }
  }

  Future<void> saveAccount(Account account) async {
    final isar = await ref.read(isarProvider.future);
    final existing = await isar.accounts.where().idEqualTo(account.id).findFirst();

    final updatedAccount = Account(
      id: account.id,
      encryptedName: account.encryptedName,
      encryptedBalance: account.encryptedBalance,
      currency: account.currency,
      type: account.type,
      providerId: account.providerId,
      group: account.group,
      updatedAt: DateTime.now(),
      isDeleted: false,
    );
    
    if (existing != null) {
      updatedAccount.isarId = existing.isarId;
    }

    await isar.writeTxn(() => isar.accounts.put(updatedAccount));
    ref.invalidateSelf();
  }

  Future<CreateAccountResult> createAccountFromForm(
      CreateAccountCommand command) async {
    final syncRepository = ref.read(accountSyncRepositoryProvider);
    final result = await syncRepository.createLocalFirst(command);
    // Guard: il provider può essere disposto durante l'await
    try { ref.invalidateSelf(); } catch (_) {}
    return result;
  }

  Future<void> syncPendingCreates() async {
    final syncRepository = ref.read(accountSyncRepositoryProvider);
    await syncRepository.syncPendingCreates();
    // Guard: il provider può essere disposto durante l'await
    try { ref.invalidateSelf(); } catch (_) {}
  }

  Future<void> deleteAccount(String accountId) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final existing =
          await isar.accounts.where().idEqualTo(accountId).findFirst();
      if (existing != null) {
        final deletedAccount = Account(
          id: existing.id,
          encryptedName: existing.encryptedName,
          encryptedBalance: existing.encryptedBalance,
          currency: existing.currency,
          type: existing.type,
          providerId: existing.providerId,
          group: existing.group,
          updatedAt: DateTime.now(),
          isDeleted: true,
        )..isarId = existing.isarId;
        await isar.accounts.put(deletedAccount);
      }
    });
    // Guard: il provider può essere disposto durante il writeTxn
    try { ref.invalidateSelf(); } catch (_) {}
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> applyTransactionDelta(String accountId, double delta) async {
    final isar = await ref.read(isarProvider.future);
    final crypto = ref.read(cryptoServiceProvider);

    await isar.writeTxn(() async {
      final account =
          await isar.accounts.where().idEqualTo(accountId).findFirst();
      if (account == null) return;

      final currentBalanceStr = await crypto.decrypt(
        account.encryptedBalance,
        scope: EncryptionScope.database,
        version: account.encryptionVersion,
        type: 'account_balance',
      );

      final currentBalance = double.tryParse(currentBalanceStr) ?? 0.0;
      final newBalance = currentBalance + delta;

      final encryptedBalance = await crypto.encrypt(
        newBalance.toString(),
        scope: EncryptionScope.database,
        type: 'account_balance',
      );

      final updatedAccount = Account(
        id: account.id,
        encryptedName: account.encryptedName,
        encryptedBalance: encryptedBalance,
        currency: account.currency,
        type: account.type,
        providerId: account.providerId,
        group: account.group,
        updatedAt: DateTime.now(),
        encryptionVersion: CryptoService.currentCryptoVersion,
      )..isarId = account.isarId;

      await isar.accounts.put(updatedAccount);
    });
    ref.invalidateSelf();
  }

  Future<void> updateAccount(String id,
      {String? encryptedName, String? groupName}) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final existing = await isar.accounts.where().idEqualTo(id).findFirst();
      if (existing != null) {
        final updated = Account(
          id: existing.id,
          encryptedName: encryptedName ?? existing.encryptedName,
          encryptedBalance: existing.encryptedBalance,
          currency: existing.currency,
          type: existing.type,
          providerId: existing.providerId,
          group: groupName ?? existing.group,
          updatedAt: DateTime.now(),
          isDeleted: existing.isDeleted,
        )..isarId = existing.isarId;
        await isar.accounts.put(updated);
      }
    });
    ref.invalidateSelf();
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountNotifier, List<Account>>(() {
  return AccountNotifier();
});
