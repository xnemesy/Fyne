import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';

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
  
  @Index()
  final DateTime createdAt;

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
    required this.createdAt,
  });

  /// Helper to create a copy with decrypted data (ONLY for UI use, not for storage)
  TransactionModel copyWithDecrypted({
    double? amount,
    String? description,
    String? counterParty,
    String? categoryName,
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
      createdAt: createdAt,
    );
    model._decryptedAmount = amount;
    model._decryptedDescription = description;
    model._decryptedCounterParty = counterParty;
    model._decryptedCategoryName = categoryName;
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

  // Secure Getters
  double? get amount => _decryptedAmount;
  String? get description => _decryptedDescription;
  String? get counterParty => _decryptedCounterParty;
  String? get categoryName => _decryptedCategoryName;

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
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

/// Lightweight representation for lists. 
/// Temporarily holds decrypted amount and minimal metadata.
class TransactionSummary {
  final String uuid;
  final double amount;
  final DateTime bookingDate;
  final String? categoryName;
  final String accountId;

  TransactionSummary({
    required this.uuid,
    required this.amount,
    required this.bookingDate,
    required this.accountId,
    this.categoryName,
  });
}
