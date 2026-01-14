import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/budget_provider.dart'; // sharing common providers like api/crypto

class AccountNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    return _fetchAndDecryptAccounts();
  }

  Future<List<Account>> _fetchAndDecryptAccounts() async {
    final api = ref.read(apiServiceProvider);
    final crypto = ref.read(cryptoServiceProvider);
    final masterKey = ref.read(masterKeyProvider);

    if (masterKey == null) return [];

    final response = await api.get('/api/accounts');
    final List<dynamic> data = response.data;
    
    final List<Account> accounts = data.map((json) => Account.fromJson(json)).toList();

    for (var account in accounts) {
      try {
        account.decryptedName = await crypto.decrypt(account.encryptedName, masterKey);
        account.decryptedBalance = await crypto.decrypt(account.encryptedBalance, masterKey);
      } catch (e) {
        account.decryptedName = "Account Criptato";
        account.decryptedBalance = "0.00";
      }
    }

    return accounts;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndDecryptAccounts());
  }
}

final accountsProvider = AsyncNotifierProvider<AccountNotifier, List<Account>>(() {
  return AccountNotifier();
});
