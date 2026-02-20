import 'package:isar_community/isar.dart';

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
  
  @Index()
  final DateTime updatedAt;

  @Index()
  final bool isDeleted;

  @Index()
  final int encryptionVersion;

  @ignore
  String? decryptedCategoryName;

  Budget({
    required this.id,
    required this.categoryUuid,
    required this.encryptedCategoryName,
    required this.limitAmount,
    required this.currentSpent,
    required this.updatedAt,
    this.isDeleted = false,
    this.encryptionVersion = 1,
    this.decryptedCategoryName,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? '',
      categoryUuid: json['category_uuid'] ?? json['categoryUuid'] ?? json['category_id'] ?? '',
      encryptedCategoryName: json['encrypted_category_name'] ?? json['encryptedCategoryName'] ?? '',
      limitAmount: (json['limit_amount'] ?? json['limitAmount'] ?? json['amount'] ?? 0.0 as num).toDouble(),
      currentSpent: (json['current_spent'] ?? json['currentSpent'] ?? 0.0 as num).toDouble(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
      encryptionVersion: json['encryption_version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_uuid': categoryUuid,
      'encrypted_category_name': encryptedCategoryName,
      'limit_amount': limitAmount,
      'current_spent': currentSpent,
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'encryption_version': encryptionVersion,
    };
  }

  double get progress => limitAmount > 0 ? (currentSpent / limitAmount) : 0;
  double get remaining => limitAmount - currentSpent;
  bool get isOverBudget => currentSpent > limitAmount;
}
