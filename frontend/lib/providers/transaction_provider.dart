import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'budget_provider.dart'; // sharing common providers like api/crypto
import 'account_provider.dart';

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final crypto = ref.read(cryptoServiceProvider);
  final masterKey = ref.read(masterKeyProvider);

  if (masterKey == null) return [];

  final response = await api.get('/api/transactions');
  final List<dynamic> data = response.data;

  final List<TransactionModel> transactions = [];
  for (var json in data) {
    final tx = TransactionModel.fromJson(json);
    
    // Decrypt on the fly
    try {
      tx.decryptedDescription = await crypto.decrypt(tx.encryptedDescription, masterKey);
      if (tx.encryptedCounterParty != null) {
        tx.decryptedCounterParty = await crypto.decrypt(tx.encryptedCounterParty!, masterKey);
      }
    } catch (e) {
      tx.decryptedDescription = "Dato Cifrato";
    }
    
    transactions.add(tx);
  }

  return transactions;
});
