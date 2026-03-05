import 'package:isar_community/isar.dart';

part 'transaction.g.dart';

@Collection()
class TransactionModel {
  Id? id;
  
  @Index(unique: true, replace: true)
  final String uuid;
  
  @Index()
  final String accountId;
  
  @Index()
  final DateTime bookingDate;
  
  final String currency;
  
  // ALL ENCRYPTED - zero sensitive data in plain text
  final String encryptedAmount;
  final String? encryptedDescription;
  final String? encryptedCounterParty;
  final String? encryptedCategoryName;
  final String? encryptedCategoryIcon;
  final String? encryptedCategoryColor;
  final String? encryptedTransactionStatus;
  @Index()
  final String? categoryUuid;
  
  @Index()
  final DateTime createdAt;

  @Index()
  final DateTime updatedAt;

  @Index()
  final int encryptionVersion;

  @Index()
  final bool isDeleted;

  TransactionModel({
    this.id,
    required this.uuid,
    required this.accountId,
    required this.bookingDate,
    required this.currency,
    required this.encryptedAmount,
    this.encryptedDescription,
    this.encryptedCounterParty,
    this.encryptedCategoryName,
    this.encryptedCategoryIcon,
    this.encryptedCategoryColor,
    this.encryptedTransactionStatus,
    this.categoryUuid,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.encryptionVersion = 1,
  });

  /// Helper to create a copy with decrypted data (ONLY for UI use, not for storage)
  TransactionModel copyWithDecrypted({
    double? amount,
    String? description,
    String? counterParty,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? transactionStatus,
  }) {
    final model = TransactionModel(
      id: id,
      uuid: uuid,
      accountId: accountId,
      bookingDate: bookingDate,
      currency: currency,
      encryptedAmount: encryptedAmount,
      encryptedDescription: encryptedDescription,
      encryptedCounterParty: encryptedCounterParty,
      encryptedCategoryName: encryptedCategoryName,
      encryptedCategoryIcon: encryptedCategoryIcon,
      encryptedCategoryColor: encryptedCategoryColor,
      encryptedTransactionStatus: encryptedTransactionStatus,
      categoryUuid: categoryUuid,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      encryptionVersion: encryptionVersion,
    );
    model._decryptedAmount = amount;
    model._decryptedDescription = description;
    model._decryptedCounterParty = counterParty;
    model._decryptedCategoryName = categoryName;
    model._decryptedCategoryIcon = categoryIcon;
    model._decryptedCategoryColor = categoryColor;
    model._decryptedTransactionStatus = transactionStatus;
    return model;
  }

  // Transient fields (Not persisted in Isar)
  @ignore
  double? _decryptedAmount;
  
  @ignore
  String? _decryptedDescription;
  
  @ignore
  String? _decryptedCounterParty;
  
  @ignore
  String? _decryptedCategoryName;
  
  @ignore
  String? _decryptedCategoryIcon;
  
  @ignore
  String? _decryptedCategoryColor;
  
  @ignore
  String? _decryptedTransactionStatus;

  // Secure Getters
  double? get amount => _decryptedAmount;
  String? get description => _decryptedDescription;
  String? get counterParty => _decryptedCounterParty;
  String? get categoryName => _decryptedCategoryName;
  String? get categoryIcon => _decryptedCategoryIcon;
  String? get categoryColor => _decryptedCategoryColor;
  String? get transactionStatus => _decryptedTransactionStatus;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      uuid: json['id'] ?? '',
      accountId: json['account_id'] ?? '',
      bookingDate: DateTime.parse(json['booking_date'] ?? DateTime.now().toIso8601String()),
      currency: json['currency'] ?? 'EUR',
      encryptedAmount: json['encrypted_amount'] ?? '',
      encryptedDescription: json['encrypted_description'],
      encryptedCounterParty: json['encrypted_counter_party'],
      encryptedCategoryName: json['encrypted_category_name'],
      encryptedCategoryIcon: json['encrypted_category_icon'],
      encryptedCategoryColor: json['encrypted_category_color'],
      encryptedTransactionStatus: json['encrypted_transaction_status'],
      categoryUuid: json['category_uuid'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
      encryptionVersion: json['encryption_version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uuid,
      'account_id': accountId,
      'booking_date': bookingDate.toIso8601String(),
      'currency': currency,
      'encrypted_amount': encryptedAmount,
      'encrypted_description': encryptedDescription,
      'encrypted_counter_party': encryptedCounterParty,
      'encrypted_category_name': encryptedCategoryName,
      'encrypted_category_icon': encryptedCategoryIcon,
      'encrypted_category_color': encryptedCategoryColor,
      'encrypted_transaction_status': encryptedTransactionStatus,
      'category_uuid': categoryUuid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'encryption_version': encryptionVersion,
    };
  }
}

/// Lightweight representation for lists.
/// Temporarily holds decrypted amount and minimal metadata.
class TransactionSummary {
  final String uuid;
  final double amount;
  final DateTime bookingDate;
  final String? categoryName;
  final String? categoryUuid;
  final String? description;
  final String? counterParty;
  final String accountId;
  final String? categoryIcon;
  final String? categoryColor;
  final String? transactionStatus;
  /// true se la decifratura AES-GCM è fallita (HMAC mismatch / chiave diversa).
  /// Il record va eliminato automaticamente — è irrecuperabile.
  final bool isCorrupted;

  TransactionSummary({
    required this.uuid,
    required this.amount,
    required this.bookingDate,
    required this.accountId,
    this.categoryName,
    this.categoryUuid,
    this.description,
    this.counterParty,
    this.categoryIcon,
    this.categoryColor,
    this.transactionStatus,
    this.isCorrupted = false,
  });
}
