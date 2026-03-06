import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/categorization_service.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/notification_service.dart';
import 'master_key_provider.dart';

class ScheduledTransaction {
  final String id;
  final double amount;
  final String frequency;
  final DateTime nextOccurrence;
  String? encryptedDescription;
  String? decryptedDescription;
  String? categoryName;
  String? categoryUuid;

  ScheduledTransaction({
    required this.id,
    required this.amount,
    required this.frequency,
    required this.nextOccurrence,
    this.encryptedDescription,
    this.decryptedDescription,
    this.categoryName,
    this.categoryUuid,
  });

  factory ScheduledTransaction.fromJson(Map<String, dynamic> json) {
    return ScheduledTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] is String ? double.tryParse(json['amount']) : (json['amount'] as num?))?.toDouble() ?? 0.0,
      frequency: json['frequency'] ?? 'MONTHLY',
      nextOccurrence: DateTime.parse(json['next_occurrence'] ?? DateTime.now().toIso8601String()),
      encryptedDescription: json['encrypted_description'],
    );
  }
}

class ScheduledNotifier extends AsyncNotifier<List<ScheduledTransaction>> {
  @override
  Future<List<ScheduledTransaction>> build() async {
    final masterKey = ref.watch(masterKeyProvider);
    return _fetchScheduled(masterKey);
  }

  Future<List<ScheduledTransaction>> _fetchScheduled(dynamic masterKey) async {
    final api = ref.read(apiServiceProvider);
    final crypto = ref.read(cryptoServiceProvider);
    final categorizationService = ref.read(categorizationServiceProvider);

    if (masterKey == null) return [];

    try {
      final response = await api.get('/api/scheduled-transactions');
      final List<dynamic> data = response.data;
      final list = data.map((j) => ScheduledTransaction.fromJson(j)).toList();

      for (var tx in list) {
        if (tx.encryptedDescription != null) {
          try {
             if (tx.encryptedDescription!.startsWith('mock_')) {
                tx.decryptedDescription = tx.encryptedDescription!.replaceFirst('mock_', '');
             } else {
                tx.decryptedDescription = await crypto.decrypt(tx.encryptedDescription!, scope: EncryptionScope.database, type: 'transaction_description');
             }

             // Run categorization
             final category = await categorizationService.categorize(tx.decryptedDescription!);
             tx.categoryName = category.name;
             tx.categoryUuid = category.id;
             
          } catch (e) {
            tx.decryptedDescription = "Programmata";
          }
        }
      }
      // Schedula reminder locali per tutte le spese caricate
      await _rescheduleNotifications(previousIds: [], transactions: list);

      return list;
    } catch (e) {
      debugPrint("Scheduled fetch error: $e");
      return [];
    }
  }

  List<ScheduledTransaction> _mockScheduled() => [];

  Future<void> refresh() async {
    final masterKey   = ref.read(masterKeyProvider);
    // Recupera IDs correnti per poter cancellare i vecchi reminder
    final previousIds = state.value?.map((tx) => tx.id).toList() ?? [];
    state = await AsyncValue.guard(() => _fetchScheduled(masterKey));
    // I nuovi reminder vengono schedulati in _fetchScheduled
    // Cancella eventuali reminder di transazioni non più presenti
    if (state.value != null) {
      final currentIds = state.value!.map((tx) => tx.id).toSet();
      for (final oldId in previousIds) {
        if (!currentIds.contains(oldId)) {
          await NotificationService().cancelTransactionReminder(oldId);
        }
      }
    }
  }

  Future<void> deleteScheduledTransaction(String id) async {
    final api = ref.read(apiServiceProvider);

    // Snapshot previous state
    final previousState = state.value;
    if (previousState == null) return;

    // Optimistic Update + cancella reminder locale
    state = AsyncValue.data(previousState.where((tx) => tx.id != id).toList());
    await NotificationService().cancelTransactionReminder(id);

    try {
      await api.post('/api/scheduled-transactions/delete', data: {'id': id});
    } catch (e) {
      debugPrint("Delete scheduled error: $e");
      // Rollback: ripristina stato e reminder
      state = AsyncValue.data(previousState);
      final tx = previousState.firstWhere((t) => t.id == id);
      await NotificationService().scheduleTransactionReminder(
        id:             tx.id,
        description:    tx.decryptedDescription ?? 'Pagamento programmato',
        amount:         tx.amount,
        nextOccurrence: tx.nextOccurrence,
      );
    }
  }

  /// Rischedula i reminder locali per le spese programmate.
  Future<void> _rescheduleNotifications({
    required List<String> previousIds,
    required List<ScheduledTransaction> transactions,
  }) async {
    await NotificationService().rescheduleTransactionReminders(
      previousIds: previousIds,
      transactions: transactions
          .where((tx) => tx.decryptedDescription != null)
          .map((tx) => {
                'id':             tx.id,
                'description':    tx.decryptedDescription!,
                'amount':         tx.amount,
                'nextOccurrence': tx.nextOccurrence,
              })
          .toList(),
    );
  }
}

final scheduledProvider = AsyncNotifierProvider<ScheduledNotifier, List<ScheduledTransaction>>(() {
  return ScheduledNotifier();
});
