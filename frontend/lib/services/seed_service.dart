import 'dart:convert';
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

/// Service for BIP39 seed phrase generation, validation, and passphrase derivation.
/// 
/// The seed phrase is the ONLY way to recover the vault on a new device.
/// Flow: 12 words → hex seed → first 32 bytes → base64 passphrase → Argon2id root key.
class SeedService {
  /// Generates a new 12-word BIP39 mnemonic.
  String generateMnemonic() {
    return bip39.generateMnemonic(strength: 128); // 128 bits = 12 words
  }

  /// Validates a mnemonic string.
  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic.trim().toLowerCase());
  }

  /// Converts a mnemonic to a deterministic passphrase.
  /// This passphrase is used as input to Argon2id for root key derivation.
  String mnemonicToPassphrase(String mnemonic) {
    final seedHex = bip39.mnemonicToSeedHex(mnemonic.trim().toLowerCase());
    // Take first 64 hex chars = 32 bytes for passphrase
    final seedBytes = _hexToBytes(seedHex.substring(0, 64));
    return base64.encode(seedBytes);
  }

  /// Returns a list of random word indices for verification.
  /// e.g. [2, 7, 10] means "verify word 3, 8, 11" (0-indexed).
  List<int> getRandomVerificationIndices({int count = 3, int totalWords = 12}) {
    final rng = Random.secure();
    final indices = <int>{};
    while (indices.length < count) {
      indices.add(rng.nextInt(totalWords));
    }
    return indices.toList()..sort();
  }

  /// Splits a mnemonic into a list of words.
  List<String> mnemonicToWords(String mnemonic) {
    return mnemonic.trim().toLowerCase().split(' ');
  }

  /// Generates a SHA-256 hash of the mnemonic for storage verification.
  /// We store this hash (NOT the mnemonic) to check if the wizard was completed.
  String hashMnemonic(String mnemonic) {
    final bytes = utf8.encode(mnemonic.trim().toLowerCase());
    final digest = sha256.convert(bytes);
    return digest.toString(); // 64 hex chars, collision-resistant
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
