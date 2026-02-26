import 'dart:convert';
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

/// Service per la generazione, validazione e derivazione della seed phrase BIP39.
///
/// La seed phrase è l'UNICO modo per recuperare il vault su un nuovo dispositivo.
/// Flusso: 24 parole → hex seed → primi 32 byte → passphrase base64 → root key Argon2id.
class SeedService {
  /// Genera un nuovo mnemonic BIP39 a 24 parole (256 bit di entropia).
  String generateMnemonic() {
    return bip39.generateMnemonic(strength: 256); // 256 bit = 24 parole
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

  /// Restituisce indici casuali per la verifica del seed.
  /// e.g. [2, 7, 10] = "verifica parola 3, 8, 11" (0-indexed).
  /// Default 24 parole (allineato al nuovo standard 256 bit).
  List<int> getRandomVerificationIndices({int count = 3, int totalWords = 24}) {
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
