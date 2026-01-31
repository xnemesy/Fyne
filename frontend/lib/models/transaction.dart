import 'package:isar/isar.dart';

part 'transaction.g.dart';

@Collection()
class TransactionModel {
  Id? id; // Isar auto-increment ID

  @Index(unique: true, replace: true)
  final String uuid; // UUID

  @Index()
  final String accountId;

  @Index()
  final DateTime bookingDate;

  final String currency;
  final String? encryptedAmount; // Encrypted amount for storage
  final String? encryptedDescription;
  final String? encryptedCounterParty;
  
  @Index()
  String categoryUuid;
  
  final String? externalId;

  @Ignore()
  double amount; // Decrypted amount for UI use

  @Ignore()
  String? decryptedDescription;

  @Ignore()
  String? decryptedCounterParty;

  @Ignore()
  String? categoryName;

  @Ignore()
  bool isHealthFocus;

  TransactionModel({
    this.id,
    required this.uuid,
    required this.accountId,
    required this.bookingDate,
    required this.currency,
    this.encryptedAmount,
    this.encryptedDescription,
    this.encryptedCounterParty,
    required this.categoryUuid,
    this.externalId,
    this.amount = 0.0,
    this.decryptedDescription,
    this.decryptedCounterParty,
    this.categoryName,
    this.isHealthFocus = false,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      // isarId is not in JSON usually, handled by local DB
      uuid: json['id'],
      accountId: json['account_id'],
      bookingDate: DateTime.parse(json['booking_date']),
      currency: json['currency'],
      encryptedAmount: json['encrypted_amount'],
      encryptedDescription: json['encrypted_description'],
      encryptedCounterParty: json['encrypted_counter_party'],
      categoryUuid: json['category_uuid'],
      externalId: json['external_id'],
      // Fallback for migration: if not encrypted, read plain amount
      amount: double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  TransactionModel copyWith({
    Id? id,
    String? uuid,
    String? accountId,
    DateTime? bookingDate,
    String? currency,
    String? encryptedAmount,
    String? encryptedDescription,
    String? encryptedCounterParty,
    String? categoryUuid,
    String? externalId,
    double? amount,
    String? decryptedDescription,
    String? decryptedCounterParty,
    String? categoryName,
    bool? isHealthFocus,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      accountId: accountId ?? this.accountId,
      bookingDate: bookingDate ?? this.bookingDate,
      currency: currency ?? this.currency,
      encryptedAmount: encryptedAmount ?? this.encryptedAmount,
      encryptedDescription: encryptedDescription ?? this.encryptedDescription,
      encryptedCounterParty: encryptedCounterParty ?? this.encryptedCounterParty,
      categoryUuid: categoryUuid ?? this.categoryUuid,
      externalId: externalId ?? this.externalId,
      amount: amount ?? this.amount,
      decryptedDescription: decryptedDescription ?? this.decryptedDescription,
      decryptedCounterParty: decryptedCounterParty ?? this.decryptedCounterParty,
      categoryName: categoryName ?? this.categoryName,
      isHealthFocus: isHealthFocus ?? this.isHealthFocus,
    );
  }
}
