import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'budget_provider.dart';
import 'master_key_provider.dart';
import 'account_provider.dart';
import '../services/categorization_service.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'privacy_provider.dart';

import 'package:csv/csv.dart';



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
      debugPrint("API Error: $e");
    }

    if (data.isEmpty) {
       debugPrint("No transactions found in DB.");
       return [];
    }

    // Process transactions in parallel
    final List<Future<TransactionModel>> futures = data.map((json) => _processSingleTransaction(json, masterKey)).toList();
    final results = await Future.wait(futures);
    
    // Sort by date descending (newest first)
    results.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    
    return results;
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
    
    // 1. Snapshot previous state for rollback
    final previousState = state.value;
    if (previousState == null) return;

    // 2. Optimistic Update: Remove from local list immediately
    final newState = previousState.where((t) => t.id != transactionId).toList();
    state = AsyncData(newState);

    try {
      // 3. Perform API Call
      await api.post('/api/transactions/delete', data: {'id': transactionId});
      
      // 4. Update related providers lazily or optimistically if critical
      // ref.invalidate(accountsProvider); // Optional: avoid if possible to prevent flicker
      // ref.invalidate(budgetsProvider);
      
    } catch (e) {
      debugPrint("Delete transaction error: $e");
      
      // 5. Rollback on error
      state = AsyncData(previousState);
      // Optionally show a snackbar/toast via a side-effect provider or listener
    }
  }

  Future<void> refresh() async {
    final masterKey = ref.read(masterKeyProvider);
    state = await AsyncValue.guard(() => _fetchTransactions(masterKey));
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});
