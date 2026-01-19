import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'budget_provider.dart';

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
                tx.decryptedDescription = await crypto.decrypt(tx.encryptedDescription!, masterKey);
             }
             
             // Run categorization
             final category = await ref.read(categorizationServiceProvider).categorize(tx.decryptedDescription!);
             tx.categoryName = category.name;
             tx.categoryUuid = category.id;
             
          } catch (e) {
            tx.decryptedDescription = "Programmata";
          }
        }
      }
      return list;
    } catch (e) {
      print("Scheduled fetch error: $e");
      return [];
    }
  }

  List<ScheduledTransaction> _mockScheduled() {
    return [
      ScheduledTransaction(
        id: "s1",
        amount: -850.00,
        frequency: "MONTHLY",
        nextOccurrence: DateTime.now().add(const Duration(days: 15)),
        encryptedDescription: "mock_Affitto Casa",
        decryptedDescription: "Affitto Casa",
      ),
      ScheduledTransaction(
        id: "s2",
        amount: -15.99,
        frequency: "MONTHLY",
        nextOccurrence: DateTime.now().add(const Duration(days: 5)),
        encryptedDescription: "mock_Netflix Premium",
        decryptedDescription: "Netflix Premium",
      ),
    ];
  }

  Future<void> refresh() async {
    final masterKey = ref.read(masterKeyProvider);
    state = await AsyncValue.guard(() => _fetchScheduled(masterKey));
  }
}

final scheduledProvider = AsyncNotifierProvider<ScheduledNotifier, List<ScheduledTransaction>>(() {
  return ScheduledNotifier();
});
