import 'budget_provider.dart';
import 'account_provider.dart';
import '../services/categorization_service.dart';

final categorizationServiceProvider = Provider((ref) => CategorizationService());

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final crypto = ref.read(cryptoServiceProvider);
  final masterKey = ref.read(masterKeyProvider);
  final categorizer = ref.read(categorizationServiceProvider);

  if (masterKey == null) return [];

  final response = await api.get('/api/transactions');
  final List<dynamic> data = response.data;

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
