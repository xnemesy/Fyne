import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypton/crypton.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/**
 * Service to handle Client-Side Encryption (Zero-Knowledge).
 * Generates keys from user password using PBKDF2 and encrypts/decrypts data.
 */
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  /// Derives a 256-bit key from a password and salt using PBKDF2.
  Future<SecretKey> deriveKey(String password, String salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000, // High iteration count for security
      bits: 256,
    );

    // Derive key
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode(salt),
    );

    return secretKey;
  }

  /// Encrypts plain text using a derived key. Returns Base64 string.
  Future<String> encrypt(String text, SecretKey secretKey) async {
    final clearText = utf8.encode(text);
    
    // Encrypt
    final secretBox = await _algorithm.encrypt(
      clearText,
      secretKey: secretKey,
    );

    // Combine nonce + cipherText + MAC for storage
    return base64.encode(secretBox.concatenation());
  }

  /// RSA Key Management for Backend-to-Client encryption
  RSAPrivateKey? _rsaPrivateKey;
  final _storage = const FlutterSecureStorage();
  static const _rsaKeyIdentifier = 'fyne_rsa_private_key';

  Future<String> getOrGeneratePublicKey() async {
    // 1. Try to load from SecureStorage
    final storedKey = await _storage.read(key: _rsaKeyIdentifier);
    if (storedKey != null) {
      _rsaPrivateKey = RSAPrivateKey.fromString(storedKey);
      return _rsaPrivateKey!.publicKey.toString();
    }

    // 2. Generate if not found
    final keyPair = RSAKeypair.fromRandom();
    _rsaPrivateKey = keyPair.privateKey;
    
    // 3. Save to SecureStorage for persistence
    await _storage.write(key: _rsaKeyIdentifier, value: _rsaPrivateKey!.toString());
    
    return keyPair.publicKey.toString();
  }

  /// Decrypts a Base64 string encrypted with our Public Key by the backend.
  Future<String> decryptWithPrivateKey(String base64Data) async {
    if (_rsaPrivateKey == null) {
      await getOrGeneratePublicKey();
    }
    return _rsaPrivateKey!.decrypt(base64Data);
  }
  
  /// Helper for testing: Encrypts data as if the backend did it
  Future<String> encryptWithSelfPublicKey(String text) async {
     if (_rsaPrivateKey == null) {
      await getOrGeneratePublicKey();
    }
    return _rsaPrivateKey!.publicKey.encrypt(text);
  }

  /// Decrypts a Base64 string using a derived key.
  Future<String> decrypt(String base64Data, SecretKey secretKey) async {
    final data = base64.decode(base64Data);
    
    // The concatenation format for AesCbc in 'cryptography' package includes nonce and MAC
    final secretBox = SecretBox.fromConcatenation(
      data,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );

    final clearText = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(clearText);
  }
}
