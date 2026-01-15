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

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final crypto = ref.read(cryptoServiceProvider);
  final masterKey = ref.watch(masterKeyProvider);
  final categorizer = ref.read(categorizationServiceProvider);

  if (masterKey == null) return [];

  List<dynamic> data = [];
  
  if (useMockData) {
     final realisticData = [
      "Esselunga Milano", "Lidl Roma", "Carrefour Express", 
      "Netflix Monthly", "Spotify Premium", "Disney Plus", 
      "Virgin Active City", "Farmacia Centrale", "Amazon IT Order", 
      "Zalando Reso", "Benzina Eni", "Biglietto Trenitalia", 
      "Uber Black", "McDonalds Drive", "Poke House", 
      "Scommesse Snai", "Tabacchi n.12"
    ];
    
    final random = Random();
    for (int i = 0; i < 200; i++) {
      final desc = realisticData[random.nextInt(realisticData.length)];
      final encryptedDesc = await crypto.encryptWithSelfPublicKey("$desc #${i}");
      
      data.add({
        "id": "mock_$i",
        "accountId": "mock_acc",
        "amount": -(random.nextDouble() * 150 + 2),
        "currency": "EUR",
        "encryptedDescription": encryptedDesc,
        "bookingDate": DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
      });
    }
  } else {
    try {
      final response = await api.get('/api/transactions');
      data = response.data;
    } catch (e) {
      print("API Error: $e");
    }
  }

  final List<TransactionModel> transactions = [];
  for (var json in data) {
    final tx = TransactionModel.fromJson(json);
    
    // Decrypt on the fly
    try {
      // 1. Try AES (Master Key) - used for manual entries
      tx.decryptedDescription = await crypto.decrypt(tx.encryptedDescription, masterKey);
      if (tx.encryptedCounterParty != null) {
        tx.decryptedCounterParty = await crypto.decrypt(tx.encryptedCounterParty!, masterKey);
      }
    } catch (e) {
      try {
        // 2. Try RSA (Private Key) - used for banking syncs
        tx.decryptedDescription = await crypto.decryptWithPrivateKey(tx.encryptedDescription);
        if (tx.encryptedCounterParty != null) {
          tx.decryptedCounterParty = await crypto.decryptWithPrivateKey(tx.encryptedCounterParty!);
        }
      } catch (e2) {
        tx.decryptedDescription = "Dato Cifrato";
      }
    }
    // 3. Local Intelligence: Categorize based on decrypted description
    if (tx.decryptedDescription != null) {
      final category = await categorizer.categorize(tx.decryptedDescription!);
      tx.categoryUuid = category.id;
      tx.categoryName = category.name; // Keep local for UI
      tx.isHealthFocus = category.isHealthFocus;
    }
    
    transactions.add(tx);
  }

  return transactions;
});
