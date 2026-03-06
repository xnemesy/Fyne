import 'package:flutter/foundation.dart';

/// Classificazione dei fallimenti crittografici.
///
/// - [masterKeyMissing]: vault bloccato o chiave RSA assente.
/// - [corruptedBlob]: HMAC mismatch o payload malformato → record irrecuperabile.
/// - [unknown]: eccezione generica non classificabile.
enum CryptoFailureReason { masterKeyMissing, corruptedBlob, unknown }

/// Utility per il logging silente dei fallimenti crittografici.
///
/// Non invia dati al cloud — scrive esclusivamente su console (debugPrint).
/// Formato: `🔐 [CRYPTO_LOG] <reason> | <component> | <entityId> | <timestamp>`
///
/// Usare [CryptoLog.record] nei catch block dei provider che decrittano dati.
class CryptoLog {
  CryptoLog._();

  /// Registra un fallimento crittografico.
  ///
  /// - [component]: identificatore del layer sorgente (es. 'account_overview', 'tx_repository')
  /// - [entityId]: UUID dell'entità coinvolta (account id, transaction uuid)
  /// - [error]: l'eccezione catturata
  static void record({
    required String component,
    required String entityId,
    required Object error,
  }) {
    final reason = _classify(error.toString());
    final ts = DateTime.now().toIso8601String();
    debugPrint('🔐 [CRYPTO_LOG] $reason | $component | $entityId | $ts | $error');
  }

  /// Classifica l'errore dal messaggio dell'eccezione generata da CryptoService.
  static CryptoFailureReason _classify(String msg) {
    if (msg.contains('Vault locked') || msg.contains('RSA Key missing')) {
      return CryptoFailureReason.masterKeyMissing;
    }
    if (msg.contains('HMAC mismatch') || msg.contains('Invalid payload')) {
      return CryptoFailureReason.corruptedBlob;
    }
    return CryptoFailureReason.unknown;
  }
}
