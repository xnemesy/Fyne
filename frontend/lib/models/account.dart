import 'package:isar/isar.dart';

part 'account.g.dart';

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

@collection
class Account {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  
  final String encryptedName;
  final String encryptedBalance;
  final String currency;
  
  @enumerated
  final AccountType type;
  
  final String? providerId;
  final String group;

  @ignore
  String? decryptedName;
  
  @ignore
  String? decryptedBalance;

  Account({
    required this.id,
    required this.encryptedName,
    required this.encryptedBalance,
    required this.currency,
    required this.type,
    this.providerId,
    this.group = 'Personale',
    this.decryptedName,
    this.decryptedBalance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      encryptedName: json['encrypted_name'] ?? json['encryptedName'] ?? '',
      encryptedBalance: json['encrypted_balance'] ?? json['encryptedBalance'] ?? '',
      currency: json['currency'] ?? 'EUR',
      type: AccountType.fromString(json['type'] ?? 'checking'),
      providerId: json['provider_id'],
      group: json['group_name'] ?? json['group'] ?? 'Personale',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'encrypted_name': encryptedName,
      'encrypted_balance': encryptedBalance,
      'currency': currency,
      'type': type.name,
      'provider_id': providerId,
      'group_name': group,
    };
  }
}
