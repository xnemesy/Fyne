import 'package:isar/isar.dart';
import 'api_service.dart';
import 'crypto_service.dart';
import 'categorization_service.dart';

/**
 * Local model for planned/recurring transactions.
 */
@collection
class PlannedTransaction {
  Id id = Isar.autoIncrement;

  late String encryptedDescription;
  late double amount;
  late String categoryUuid;
  late String accountId;
  
  late DateTime lastExecuted;
  late int frequencyDays; // e.g. 30 for monthly
}

/**
 * Scheduler Service: Checks and executes planned transactions on app startup.
 * Runs strictly on-device to maintain Zer-Knowledge.
 */
class SchedulerService {
  final Isar isar;
  final ApiService api;
  final CryptoService crypto;

  SchedulerService({
    required this.isar,
    required this.api,
    required this.crypto,
  });

  /**
   * Scans local DB for transactions that need execution today.
   */
  Future<void> checkAndExecutePlanned(dynamic masterKey) async {
    final now = DateTime.now();
    final pending = await isar.plannedTransactions
        .filter()
        .lastExecutedLessThan(now.subtract(const Duration(days: 1))) // Simplified check
        .findAll();

    for (var planned in pending) {
      final daysSinceLast = now.difference(planned.lastExecuted).inDays;
      
      if (daysSinceLast >= planned.frequencyDays) {
        await _execute(planned, masterKey);
      }
    }
  }

  Future<void> _execute(PlannedTransaction planned, dynamic masterKey) async {
    try {
      // 1. Decrypt locally to get details if needed (or just send encrypted blob)
      // Since it's already encrypted in Isar, we can just send it or re-encrypt
      
      // 2. Post to manual transaction endpoint
      await api.post('/api/transactions/manual', data: {
        'accountId': planned.accountId,
        'amount': planned.amount,
        'currency': 'EUR',
        'encryptedDescription': planned.encryptedDescription,
        'categoryUuid': planned.categoryUuid,
        'date': DateTime.now().toIso8601String(),
      });

      // 3. Update local record
      await isar.writeTxn(() async {
        planned.lastExecuted = DateTime.now();
        await isar.plannedTransactions.put(planned);
      });
      
      print("Scheduler: Executed planned transaction ${planned.id}");
    } catch (e) {
      print("Scheduler Error: $e");
    }
  }
}
