import 'package:cryptography/cryptography.dart';
import 'api_service.dart';
import 'crypto_service.dart';
import 'categorization_service.dart';

class SyncService {
  final ApiService api;
  final CryptoService crypto;
  final CategorizationService categorization;

  SyncService({
    required this.api,
    required this.crypto,
    required this.categorization,
  });

  /**
   * Orchestrates the Zero-Knowledge Sync Flow:
   * 1. Fetch raw transactions from Banking Provider (via Backend Proxy)
   * 2. Categorize (On-Device, Clear-text)
   * 3. Encrypt (On-Device, Clear-text -> AES-256)
   * 4. Upload results to Backend for persistence
   */
  Future<void> performZeroKnowledgeSync(String accountId, SecretKey masterKey) async {
    // 1. Fetch raw (temporary) transactions from provider
    // Note: Backend acts as a pure proxy here, not saving until we send results
    final fetchResponse = await api.get('/api/banking/fetch-raw/$accountId');
    final List<dynamic> rawTransactions = fetchResponse.data;

    List<Map<String, dynamic>> processedData = [];

    for (var raw in rawTransactions) {
      // 2. Categorize (On-Device)
      final description = raw['description'] ?? 'No description';
      final categoryUuid = await categorization.categorize(description);

      // 3. Encrypt (On-Device)
      final encryptedDescription = await crypto.encrypt(description, masterKey);
      final encryptedCounterParty = await crypto.encrypt(raw['counterPartyName'] ?? 'Unknown', masterKey);

      processedData.add({
        'externalId': raw['externalId'],
        'amount': raw['amount'], // Amount remains clear for server-side budgeting
        'currency': raw['currency'],
        'description': encryptedDescription,
        'counterPartyName': encryptedCounterParty,
        'categoryUuid': categoryUuid,
        'bookingDate': raw['bookingDate'],
      });
    }

    // 4. Send back to backend for secure persistence
    await api.post('/api/banking/sync-results', data: {
      'accountId': accountId,
      'transactions': processedData,
    });
  }
}
