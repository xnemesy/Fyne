/**
 * Data model for a Banking Account (Wallet).
 * Everything is encrypted on the server, decrypted only locally.
 */
enum AccountType {
  checking,
  credit,
  savings,
  loan,
  cash,
  investment,
  crypto;

  static AccountType fromString(String val) {
    return AccountType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AccountType.checking,
    );
  }
}

class Account {
  final String id;
  final String encryptedName;
  final String encryptedBalance;
  final String currency;
  final AccountType type;
  final String? providerId;
  
  String? decryptedName;
  String? decryptedBalance;

  Account({
    required this.id,
    required this.encryptedName,
    required this.encryptedBalance,
    required this.currency,
    required this.type,
    this.providerId,
    this.decryptedName,
    this.decryptedBalance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      encryptedName: json['encrypted_name'],
      encryptedBalance: json['encrypted_balance'],
      currency: json['currency'],
      type: AccountType.fromString(json['type'] ?? 'checking'),
      providerId: json['provider_id'],
    );
  }
}
