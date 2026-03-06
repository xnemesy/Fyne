import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:crypton/crypton.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../providers/storage_provider.dart';

/// Service to handle Client-Side Encryption (Zero-Knowledge v2.2 - Signal Level).
/// Implements Root Key derivation via Argon2id (mobile-friendly),
/// Scoped Key expansion via HKDF with vault salt and schema versioning,
/// and Authenticated Encryption via AES-GCM with structured AAD.
///
/// DESIGN: No sensitive key material is persisted on disk beyond the RSA keys.
enum EncryptionScope {
  database,
  apiToken,
  backup,
  integrity;

  String contextTag(int version) => 'fyne:v$version:scope:$name';
}

class CryptoService {
  final FlutterSecureStorage _storage;
  final _aesGcm = AesGcm.with256bits();

  CryptoService({required FlutterSecureStorage storage}) : _storage = storage;

  // Root Key material held in memory only, encapsulated in a session
  _VaultSession? _session;

  bool get isUnlocked => _session != null;
  bool get isLocked => _session == null;
  
  // Device-specific salt used for HKDF expansion
  static const _vaultSaltIdentifier = 'fyne_vault_salt';
  static const _rsaKeyIdentifier = 'fyne_rsa_private_key';

  // Current Cryptographic Schema Version
  static const int currentCryptoVersion = 1;

  /// Derives a 256-bit Root Key from a password and user salt using Argon2id.
  Future<SecretKey> deriveRootKey(String password, String salt) async {
    final argon2 = Argon2id(
      memory: 32768, // 32 MB (mobile friendly)
      iterations: 4,
      parallelism: 2,
      hashLength: 32,
    );

    return await argon2.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode(salt.padRight(16, '0').substring(0, 16)),
    );
  }

  /// Encrypts plain text using AES-GCM + HMAC (Signal-level).
  /// Flow: AES-GCM(plaintext) -> ciphertext -> HMAC(ciphertext, integrityKey) -> append MAC.
  Future<String> encrypt(String text, {
    required EncryptionScope scope,
    int? version,
    String type = 'record',
    String? contextId, // e.g. providerId to prevent cross-account replay
  }) async {
    if (_session == null) throw Exception('Vault locked');
    
    final targetVersion = version ?? currentCryptoVersion;

    // 1. Get Keys
    final encryptionKey = await _session!.getScopedKey(scope, targetVersion, this);
    final integrityKey = await _session!.getScopedKey(EncryptionScope.integrity, targetVersion, this);

    // 2. Encrypt (AES-GCM)
    final clearText = utf8.encode(text);
    final aad = 'fyne:v$targetVersion:${scope.name}:$type${contextId != null ? ':$contextId' : ''}';
    
    final secretBox = await _aesGcm.encrypt(
      clearText,
      secretKey: encryptionKey,
      aad: utf8.encode(aad),
    );
    final cipherBytes = secretBox.concatenation();

    // 3. Authenticate (HMAC-SHA256)
    final hmac = Hmac.sha256();
    final mac = await hmac.calculateMac(
      cipherBytes,
      secretKey: integrityKey,
    );

    // 4. Serialize: [HMAC bytes] + [AES-GCM Ciphertext]
    // HMAC-SHA256 is 32 bytes fixed length.
    final payload = [...mac.bytes, ...cipherBytes];
    return base64.encode(payload);
  }

  /// Decrypts a payload verifying HMAC first (Encrypt-then-MAC).
  Future<String> decrypt(String base64Data, {
    required EncryptionScope scope,
    int? version,
    String type = 'record',
    String? contextId,
  }) async {
    if (_session == null) throw Exception('Vault locked');
    
    final targetVersion = version ?? currentCryptoVersion;

    final data = base64.decode(base64Data);
    if (data.length < 32) throw Exception('Invalid payload length');

    // 1. Split HMAC and Ciphertext
    final receivedMac = data.sublist(0, 32);
    final cipherBytes = data.sublist(32);

    // 2. Verify HMAC (Integrity Key) first!
    final integrityKey = await _session!.getScopedKey(EncryptionScope.integrity, targetVersion, this);
    final hmac = Hmac.sha256();
    final calculatedMac = await hmac.calculateMac(
      cipherBytes,
      secretKey: integrityKey,
    );

    if (!_constantTimeCompare(receivedMac, calculatedMac.bytes)) {
      throw Exception('VaultIntegrityException: HMAC mismatch. Record corrupted or tampered.');
    }

    // 3. Decrypt (AES-GCM)
    final encryptionKey = await _session!.getScopedKey(scope, targetVersion, this);
    final aad = 'fyne:v$targetVersion:${scope.name}:$type${contextId != null ? ':$contextId' : ''}';
    
    final secretBox = SecretBox.fromConcatenation(
      cipherBytes,
      nonceLength: _aesGcm.nonceLength,
      macLength: _aesGcm.macAlgorithm.macLength,
    );

    final clearText = await _aesGcm.decrypt(
      secretBox,
      secretKey: encryptionKey,
      aad: utf8.encode(aad),
    );

    return utf8.decode(clearText);
  }

  /// Initializes the Root Key in memory. 
  Future<void> unlock(String passphrase, String salt) async {
    debugPrint("🔐 [CRYPTO] Unlocking vault with salt: $salt");
    wipe(); // Ensure previous state is cleared
    final rootKey = await deriveRootKey(passphrase, salt);
    _session = _VaultSession(rootKey);
    debugPrint("🔐 [CRYPTO] Vault session established.");
  }

  /// Securely wipes all key material from memory.
  Future<void> wipe() async {
    if (_session != null) {
      await _session!.wipe(this);
      _session = null;
    }
    _rsaPrivateKey = null;
  }



  /// Retrieves a Scoped Key (Cached in Session).
  Future<SecretKey> getScopedKey(EncryptionScope scope, {int? version}) async {
    if (_session == null) throw Exception('Vault locked.');
    return _session!.getScopedKey(scope, version ?? currentCryptoVersion, this);
  }

  /// Internal: Expands a Scoped Key from the Root Key using HKDF.
  Future<SecretKey> _expandKeyInternal(SecretKey rootKey, EncryptionScope scope, int version) async {
    // Ensure we have a vault salt
    String? vaultSalt = await _storage.read(key: _vaultSaltIdentifier);
    if (vaultSalt == null) {
      vaultSalt = base64.encode(SecretKeyData.random(length: 16).bytes);
      await _storage.write(key: _vaultSaltIdentifier, value: vaultSalt);
    }

    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );

    final infoString = '${scope.contextTag(version)}:schema_v1';
    
    return await hkdf.deriveKey(
      secretKey: rootKey,
      nonce: base64.decode(vaultSalt),
      info: utf8.encode(infoString),
    );
  }

  /// Internal: Best-effort hardened wipe of secret key bytes in RAM.
  Future<void> _hardWipeSecretKey(SecretKey key) async {
    try {
      final secretKeyData = await key.extract();
      final bytes = secretKeyData.bytes;
      // Overwrite buffer with zeros
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    } catch (_) {
      // Opaque keys might not allow extraction, but we try
    }
  }
  
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// HMAC Integrity Check
  /// Generates an HMAC-SHA256 signature for a data record using the integrity key.
  Future<String> signRecord(String data, {String type = 'record', int? version}) async {
    final targetVersion = version ?? currentCryptoVersion;
    final integrityKey = await getScopedKey(EncryptionScope.integrity, version: targetVersion);
    final hmac = Hmac.sha256();
    // AAD-like context bound signature
    final contextData = 'fyne:v$targetVersion:integrity:$type:$data';
    final signature = await hmac.calculateMac(
      utf8.encode(contextData),
      secretKey: integrityKey,
    );
    return base64.encode(signature.bytes);
  }

  /// Verifies an HMAC signature for a record.
  Future<bool> verifyRecord(String data, String signatureBase64, {String type = 'record', int? version}) async {
    final targetVersion = version ?? currentCryptoVersion;
    final integrityKey = await getScopedKey(EncryptionScope.integrity, version: targetVersion);
    final actualSignature = base64.decode(signatureBase64);
    final contextData = 'fyne:v$targetVersion:integrity:$type:$data';
    
    final hmac = Hmac.sha256();
    final expectedMac = await hmac.calculateMac(
      utf8.encode(contextData),
      secretKey: integrityKey,
    );
    
    return _constantTimeCompare(actualSignature, expectedMac.bytes);
  }

  /// RSA Key Management (Sync Identity)
  RSAPrivateKey? _rsaPrivateKey;

  Future<String> getOrGeneratePublicKey() async {
    final storedKey = await _storage.read(key: _rsaKeyIdentifier);
    if (storedKey != null) {
      _rsaPrivateKey = RSAPrivateKey.fromString(storedKey);
      return _rsaPrivateKey!.publicKey.toString();
    }

    final keyPair = RSAKeypair.fromRandom();
    _rsaPrivateKey = keyPair.privateKey;
    await _storage.write(key: _rsaKeyIdentifier, value: _rsaPrivateKey!.toString());
    return keyPair.publicKey.toString();
  }

  Future<String> decryptWithPrivateKey(String base64Data) async {
    if (_rsaPrivateKey == null) await getOrGeneratePublicKey();
    if (_rsaPrivateKey == null) throw Exception('RSA Key missing');
    return _rsaPrivateKey!.decrypt(base64Data);
  }
}

/// Encapsulated Session to manage key lifecycle and caching.
class _VaultSession {
  final SecretKey _rootKey;
  // Cache key is "version:scope_index"
  final Map<String, SecretKey> _scopedCache = {};

  _VaultSession(this._rootKey);

  Future<SecretKey> getScopedKey(EncryptionScope scope, int version, CryptoService service) async {
    final cacheKey = '$version:${scope.index}';
    if (_scopedCache.containsKey(cacheKey)) {
      return _scopedCache[cacheKey]!;
    }
    
    // Expand and cache
    final derived = await service._expandKeyInternal(_rootKey, scope, version);
    _scopedCache[cacheKey] = derived;
    return derived;
  }

  Future<void> wipe(CryptoService service) async {
    await service._hardWipeSecretKey(_rootKey);
    for (final key in _scopedCache.values) {
      await service._hardWipeSecretKey(key);
    }
    _scopedCache.clear();
  }
}

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return CryptoService(storage: storage);
});
