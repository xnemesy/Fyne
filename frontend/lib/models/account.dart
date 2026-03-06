import 'package:isar_community/isar.dart';

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

enum AccountSyncStatus {
  synced,
  pendingCreate,
  failedCreate;

  static AccountSyncStatus fromString(String? value) {
    return AccountSyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountSyncStatus.synced,
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

  @Index()
  final DateTime updatedAt;

  @Index()
  final bool isDeleted;

  @Index()
  final int encryptionVersion;

  @enumerated
  final AccountSyncStatus syncStatus;

  final String? remoteError;

  @ignore
  String? decryptedName;

  @ignore
  String? decryptedBalance;

  @ignore
  bool get isCorrupted => decryptedName == null;

  Account({
    required this.id,
    required this.encryptedName,
    required this.encryptedBalance,
    required this.currency,
    required this.type,
    this.providerId,
    this.group = 'Personale',
    required this.updatedAt,
    this.isDeleted = false,
    this.encryptionVersion = 1,
    this.syncStatus = AccountSyncStatus.synced,
    this.remoteError,
    this.decryptedName,
    this.decryptedBalance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw ArgumentError('Account ID è obbligatorio nel JSON');
    }
    return Account(
      id: json['id'],
      encryptedName: json['encrypted_name'] ?? json['encryptedName'] ?? '',
      encryptedBalance:
          json['encrypted_balance'] ?? json['encryptedBalance'] ?? '',
      currency: json['currency'] ?? 'EUR',
      type: AccountType.fromString(json['type'] ?? 'checking'),
      providerId: json['provider_id'],
      group: json['group_name'] ?? json['group'] ?? 'Personale',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
      encryptionVersion: json['encryption_version'] ?? 1,
      syncStatus: AccountSyncStatus.fromString(json['sync_status']),
      remoteError: json['remote_error'],
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
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'encryption_version': encryptionVersion,
      'sync_status': syncStatus.name,
      'remote_error': remoteError,
    };
  }
}
