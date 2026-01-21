import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'master_key_provider.dart';
import '../providers/budget_provider.dart';

class AccountNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final masterKey = ref.watch(masterKeyProvider);
    return _fetchAndDecryptAccounts(masterKey);
  }

  Future<List<Account>> _fetchAndDecryptAccounts(dynamic masterKey) async {
    final api = ref.read(apiServiceProvider);
    final crypto = ref.read(cryptoServiceProvider);

    if (masterKey == null) return [];

    final response = await api.get('/api/accounts');
    final List<dynamic> data = response.data;
    
    final List<Account> accounts = data.map((json) => Account.fromJson(json)).toList();

    for (var account in accounts) {
      try {
        // 1. Try AES (Manual accounts)
        account.decryptedName = await crypto.decrypt(account.encryptedName, masterKey);
        account.decryptedBalance = await crypto.decrypt(account.encryptedBalance, masterKey);
      } catch (e) {
        try {
          // 2. Try RSA (Synced accounts)
          account.decryptedName = await crypto.decryptWithPrivateKey(account.encryptedName);
          account.decryptedBalance = await crypto.decryptWithPrivateKey(account.encryptedBalance);
        } catch (e2) {
          account.decryptedName = "Account Criptato";
          account.decryptedBalance = "0.00";
        }
      }
    }
    return accounts;
  }

  Future<void> refresh() async {
    final masterKey = ref.read(masterKeyProvider);
    state = await AsyncValue.guard(() => _fetchAndDecryptAccounts(masterKey));
  }

  Future<void> updateAccount(String accountId, {String? encryptedName, String? groupName}) async {
    final api = ref.read(apiServiceProvider);
    
    try {
      await api.put('/api/accounts/$accountId', data: {
        if (encryptedName != null) 'encrypted_name': encryptedName,
        if (groupName != null) 'group_name': groupName,
      });
      refresh();
    } catch (e) {
      print("Update account error: $e");
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final api = ref.read(apiServiceProvider);
    
    // 1. Snapshot previous state
    final previousState = state.value;
    if (previousState == null) return;

    // 2. Optimistic Update
    final newState = previousState.where((a) => a.id != accountId).toList();
    state = AsyncData(newState);

    try {
      // 3. API Call
      await api.post('/api/accounts/delete', data: {'id': accountId});
      
      // 4. Invalidate related providers lazily
      // ref.invalidate(budgetsProvider);
    } catch (e) {
      print("Delete account error: $e");
      // 5. Rollback
      state = AsyncData(previousState);
    }
  }

  void updateLocalBalance(String accountId, String newDecryptedBalance) {
    final currentState = state;
    if (currentState is AsyncData<List<Account>>) {
      final List<Account> currentList = currentState.value;
      // Create a shallow copy of the list
      final newList = List<Account>.from(currentList);
      
      for (var account in newList) {
        if (account.id == accountId) {
          account.decryptedBalance = newDecryptedBalance;
          break;
        }
      }
      state = AsyncData(newList);
    }
  }
}

final accountsProvider = AsyncNotifierProvider<AccountNotifier, List<Account>>(() {
  return AccountNotifier();
});
