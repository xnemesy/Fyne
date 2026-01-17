/**
 * Data model for Budget.
 * Includes both encrypted fields (from server) and decrypted fields (local only).
 */
class Budget {
  final String id;
  final String categoryUuid;
  final String encryptedCategoryName;
  final double limitAmount;
  final double currentSpent;
  String? decryptedCategoryName; // Populated only after decryption

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
      id: json['id'],
      categoryUuid: json['category_uuid'] ?? json['categoryUuid'] ?? json['category_id'] ?? '',
      encryptedCategoryName: json['encrypted_category_name'] ?? json['encryptedCategoryName'] ?? '',
      limitAmount: (json['limit_amount'] ?? json['limitAmount'] ?? json['amount'] ?? 0.0 as num).toDouble(),
      currentSpent: (json['current_spent'] ?? json['currentSpent'] ?? 0.0 as num).toDouble(),
    );
  }

  double get progress => limitAmount > 0 ? (currentSpent / limitAmount) : 0;
  double get remaining => limitAmount - currentSpent;
  bool get isOverBudget => currentSpent > limitAmount;
}
