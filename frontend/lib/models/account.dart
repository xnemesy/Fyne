/**
 * Data model for a Banking Account (Wallet).
 * Everything is encrypted on the server, decrypted only locally.
 */
class Account {
  final String id;
  final String encryptedName;
  final String encryptedBalance;
  final String currency;
  final String? providerId;
  
  String? decryptedName;
  String? decryptedBalance;

  Account({
    required this.id,
    required this.encryptedName,
    required this.encryptedBalance,
    required this.currency,
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
      providerId: json['provider_id'],
    );
  }
}
