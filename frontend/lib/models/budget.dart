/**
 * Data model for Budget.
 * Includes both encrypted fields (from server) and decrypted fields (local only).
 */
class Budget {
  final String categoryUuid;
  final String encryptedCategoryName;
  final double limitAmount;
  final double currentSpent;
  String? decryptedCategoryName; // Populated only after decryption

  Budget({
    required this.categoryUuid,
    required this.encryptedCategoryName,
    required this.limitAmount,
    required this.currentSpent,
    this.decryptedCategoryName,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      categoryUuid: json['category_uuid'],
      encryptedCategoryName: json['encrypted_category_name'],
      limitAmount: (json['limit_amount'] as num).toDouble(),
      currentSpent: (json['current_spent'] as num).toDouble(),
    );
  }

  double get progress => limitAmount > 0 ? (currentSpent / limitAmount) : 0;
  double get remaining => limitAmount - currentSpent;
  bool get isOverBudget => currentSpent > limitAmount;
}
