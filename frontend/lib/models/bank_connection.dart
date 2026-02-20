import 'package:isar_community/isar.dart';

part 'bank_connection.g.dart';

/**
 * Model for an active Bank Connection (Tink).
 * Implements "Signal-level" hardening:
 * - Encrypted Envelope: Token + Expiry are encrypted together to ensure atomic integrity.
 * - Integrity Protection: Metadata is authenticated via HMAC through CryptoService.
 */
@Collection()
class BankConnection {
  Id? id;

  @Index(unique: true, replace: true)
  final String providerId; // Tink internal provider ID

  // Encrypted JSON envelope containing: {'token': '...', 'expiresAt': '...'}
  // Authenticated with contextId = providerId to prevent replay attacks.
  final String encryptedAccessEnvelope;
  
  // Encrypted separately to allow refresh without touching the main envelope
  final String encryptedRefreshToken;
  
  // Public Metadata
  final String bankName;
  final String? logoUrl;
  
  @Index()
  final int encryptionVersion;

  @Index()
  final DateTime updatedAt;

  BankConnection({
    this.id,
    required this.providerId,
    required this.encryptedAccessEnvelope,
    required this.encryptedRefreshToken,
    required this.bankName,
    this.logoUrl,
    this.encryptionVersion = 1,
    required this.updatedAt,
  });

  // Transient Fields (Not persisted)
  @ignore
  String? _decryptedAccessToken;
  
  @ignore
  DateTime? _decryptedExpiresAt;
  
  @ignore
  String? _decryptedRefreshToken;

  // Secure Getters
  String? get accessToken => _decryptedAccessToken;
  DateTime? get expiresAt => _decryptedExpiresAt;
  String? get refreshToken => _decryptedRefreshToken;

  /// Populates decrypted fields after successful CryptoService operation.
  void setDecryptedData({
    required String accessToken,
    required DateTime expiresAt,
    required String refreshToken,
  }) {
    _decryptedAccessToken = accessToken;
    _decryptedExpiresAt = expiresAt;
    _decryptedRefreshToken = refreshToken;
  }

  factory BankConnection.fromJson(Map<String, dynamic> json) {
    return BankConnection(
      providerId: json['provider_id'] ?? '',
      encryptedAccessEnvelope: json['encrypted_access_envelope'] ?? '',
      encryptedRefreshToken: json['encrypted_refresh_token'] ?? '',
      bankName: json['bank_name'] ?? '',
      logoUrl: json['logo_url'],
      encryptionVersion: json['encryption_version'] ?? 1,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'encrypted_access_envelope': encryptedAccessEnvelope,
      'encrypted_refresh_token': encryptedRefreshToken,
      'bank_name': bankName,
      'logo_url': logoUrl,
      'encryption_version': encryptionVersion,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
