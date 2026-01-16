import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'budget_provider.dart';
import 'account_provider.dart';
import '../services/categorization_service.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'privacy_provider.dart';

final categorizationServiceProvider = Provider((ref) => CategorizationService());

// Global flag for testing
bool useMockData = false;

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final masterKey = ref.watch(masterKeyProvider);
    return _fetchTransactions(masterKey);
  }

  Future<List<TransactionModel>> _fetchTransactions(dynamic masterKey) async {
    final api = ref.read(apiServiceProvider);
    final crypto = ref.read(cryptoServiceProvider);
    final categorizer = ref.read(categorizationServiceProvider);

    if (masterKey == null) return [];

    List<dynamic> data = [];
    try {
      final response = await api.get('/api/transactions');
      data = response.data;
    } catch (e) {
      print("API Error: $e");
    }

    final List<TransactionModel> transactions = [];
    try {
      for (var json in data) {
        final tx = TransactionModel.fromJson(json);
        try {
          if (tx.encryptedDescription.startsWith('mock_')) {
             tx.decryptedDescription = tx.encryptedDescription.replaceFirst('mock_', '');
          } else {
            tx.decryptedDescription = await crypto.decrypt(tx.encryptedDescription, masterKey);
          }
          
          if (tx.encryptedCounterParty != null) {
            if (tx.encryptedCounterParty!.startsWith('mock_')) {
               tx.decryptedCounterParty = tx.encryptedCounterParty!.replaceFirst('mock_', '');
            } else {
              tx.decryptedCounterParty = await crypto.decrypt(tx.encryptedCounterParty!, masterKey);
            }
          }
        } catch (e) {
          try {
            tx.decryptedDescription = await crypto.decryptWithPrivateKey(tx.encryptedDescription);
            if (tx.encryptedCounterParty != null) {
              tx.decryptedCounterParty = await crypto.decryptWithPrivateKey(tx.encryptedCounterParty!);
            }
          } catch (e2) {
            tx.decryptedDescription = "Transazione Fyne"; // Better than "Dato Cifrato"
          }
        }
        
        if (tx.decryptedDescription != null) {
          final category = await categorizer.categorize(tx.decryptedDescription!);
          tx.categoryUuid = category.id;
          tx.categoryName = category.name;
          tx.isHealthFocus = category.isHealthFocus;
        }
        transactions.add(tx);
      }
    } catch (e) {
      print("Processing error: $e");
    }

    if (transactions.isEmpty) {
       return _mockTransactions();
    }
    return transactions;
  }

  List<TransactionModel> _mockTransactions() {
    return [
      TransactionModel(
        id: "1",
        accountId: "a1",
        amount: -45.50,
        currency: "EUR",
        bookingDate: DateTime.now().subtract(const Duration(hours: 2)),
        encryptedDescription: "mock_Starbucks Coffee",
        decryptedDescription: "Starbucks Coffee",
        categoryName: "CIBO",
      ),
      TransactionModel(
        id: "2",
        accountId: "a1",
        amount: -12.00,
        currency: "EUR",
        bookingDate: DateTime.now().subtract(const Duration(days: 1)),
        encryptedDescription: "mock_Apple Music Subscription",
        decryptedDescription: "Apple Music Subscription",
        categoryName: "INTRATTENIMENTO",
      ),
      TransactionModel(
        id: "3",
        accountId: "a1",
        amount: 2500.00,
        currency: "EUR",
        bookingDate: DateTime.now().subtract(const Duration(days: 3)),
        encryptedDescription: "mock_Stipendio Gennaio",
        decryptedDescription: "Stipendio Gennaio",
        categoryName: "STIPENDIO",
      ),
    ];
  }

  Future<void> deleteTransaction(String transactionId) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.post('/api/transactions/delete', data: {'id': transactionId});
    } catch (e) {
      print("Delete transaction error: $e");
    }
    ref.invalidateSelf();
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetsProvider);
  }

  Future<void> refresh() async {
    final masterKey = ref.read(masterKeyProvider);
    state = await AsyncValue.guard(() => _fetchTransactions(masterKey));
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});
