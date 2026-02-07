import 'package:isar/isar.dart';

part 'budget.g.dart';

/**
 * Data model for Budget.
 * Includes both encrypted fields (from server) and decrypted fields (local only).
 */
@collection
class Budget {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  
  final String categoryUuid;
  final String encryptedCategoryName;
  final double limitAmount;
  final double currentSpent;
  
  @ignore
  String? decryptedCategoryName;

  Budget({
    required this.id,
    required this.categoryUuid,
    required this.encryptedCategoryName,
    required this.limitAmount,
    required this.currentSpent,
    this.decryptedCategoryName,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? '',
      categoryUuid: json['category_uuid'] ?? json['categoryUuid'] ?? json['category_id'] ?? '',
      encryptedCategoryName: json['encrypted_category_name'] ?? json['encryptedCategoryName'] ?? '',
      limitAmount: (json['limit_amount'] ?? json['limitAmount'] ?? json['amount'] ?? 0.0 as num).toDouble(),
      currentSpent: (json['current_spent'] ?? json['currentSpent'] ?? 0.0 as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_uuid': categoryUuid,
      'encrypted_category_name': encryptedCategoryName,
      'limit_amount': limitAmount,
      'current_spent': currentSpent,
    };
  }

  double get progress => limitAmount > 0 ? (currentSpent / limitAmount) : 0;
  double get remaining => limitAmount - currentSpent;
  bool get isOverBudget => currentSpent > limitAmount;
}
