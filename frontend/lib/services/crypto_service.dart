import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypton/crypton.dart';

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

  Future<String> getOrGeneratePublicKey() async {
    // In a real app, read from SecureStorage
    if (_rsaPrivateKey == null) {
      final keyPair = RSAKeypair.fromRandom();
      _rsaPrivateKey = keyPair.privateKey;
      return keyPair.publicKey.toString();
    }
    return _rsaPrivateKey!.publicKey.toString();
  }

  /// Decrypts a Base64 string encrypted with our Public Key by the backend.
  Future<String> decryptWithPrivateKey(String base64Data) async {
    if (_rsaPrivateKey == null) throw Exception("RSA Private Key not initialized");
    return _rsaPrivateKey!.decrypt(base64Data);
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
