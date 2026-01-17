import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'budget_provider.dart';
import 'account_provider.dart';
import '../services/categorization_service.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'privacy_provider.dart';

import 'package:csv/csv.dart';

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
    if (masterKey == null) return [];

    List<dynamic> data = [];
    try {
      final response = await api.get('/api/transactions');
      data = response.data;
    } catch (e) {
      print("API Error: $e");
    }

    if (data.isEmpty) {
       return _mockTransactions();
    }

    // Process transactions in parallel
    final List<Future<TransactionModel>> futures = data.map((json) => _processSingleTransaction(json, masterKey)).toList();
    return await Future.wait(futures);
  }

  Future<TransactionModel> _processSingleTransaction(dynamic json, dynamic masterKey) async {
    final crypto = ref.read(cryptoServiceProvider);
    final categorizer = ref.read(categorizationServiceProvider);
    final tx = TransactionModel.fromJson(json);

    try {
      // Decrypt Description
      if (tx.encryptedDescription.startsWith('mock_')) {
        tx.decryptedDescription = tx.encryptedDescription.replaceFirst('mock_', '');
      } else {
        tx.decryptedDescription = await crypto.decrypt(tx.encryptedDescription, masterKey);
      }
      
      // Decrypt CounterParty
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
        tx.decryptedDescription = "Transazione Fyne";
      }
    }
    
    // Categorize
    if (tx.decryptedDescription != null) {
      final category = await categorizer.categorize(tx.decryptedDescription!);
      tx.categoryUuid = category.id;
      tx.categoryName = category.name;
      tx.isHealthFocus = category.isHealthFocus;
    }

    return tx;
  }

  Future<String> exportToCsv() async {
    final transactions = state.value ?? [];
    if (transactions.isEmpty) return "";

    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      "ID",
      "Data",
      "Descrizione",
      "Beneficiario",
      "Importo",
      "Valuta",
      "Categoria"
    ]);

    for (var tx in transactions) {
      rows.add([
        tx.id,
        tx.bookingDate.toIso8601String(),
        tx.decryptedDescription ?? "",
        tx.decryptedCounterParty ?? "",
        tx.amount,
        tx.currency,
        tx.categoryName ?? ""
      ]);
    }

    return const ListToCsvConverter().convert(rows);
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
        categoryUuid: "mock_cat_1",
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
        categoryUuid: "mock_cat_2",
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
        categoryUuid: "mock_cat_3",
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
