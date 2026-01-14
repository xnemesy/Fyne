class TransactionModel {
  final String id;
  final String accountId;
  final double amount;
  final String currency;
  final String encryptedDescription;
  final String? encryptedCounterParty;
  String categoryUuid;
  final DateTime bookingDate;
  final String? externalId;

  String? decryptedDescription;
  String? decryptedCounterParty;
  String? categoryName;
  bool isHealthFocus;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.encryptedDescription,
    this.encryptedCounterParty,
    required this.categoryUuid,
    required this.bookingDate,
    this.externalId,
    this.decryptedDescription,
    this.decryptedCounterParty,
    this.categoryName,
    this.isHealthFocus = false,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      accountId: json['account_id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      encryptedDescription: json['encrypted_description'],
      encryptedCounterParty: json['encrypted_counter_party'],
      categoryUuid: json['category_uuid'],
      bookingDate: DateTime.parse(json['booking_date']),
      externalId: json['external_id'],
    );
  }
}
