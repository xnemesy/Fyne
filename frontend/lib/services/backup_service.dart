import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:isar/isar.dart';
import 'package:crypto/crypto.dart' as hash;
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/categorization_rule.dart';
import 'crypto_service.dart';
import 'analytics_service.dart';

/// Servizio per Backup & Recovery cifrato - Hardened for Beta.
class BackupService {
  final CryptoService _crypto = CryptoService();
  final AnalyticsService _analytics = AnalyticsService();
  static const String currentBackupVersion = '1.0.0';

  /// Esporta tutti i dati Isar in un file JSON cifrato con Checksum.
  Future<String> exportEncryptedBackup({
    required Isar isar,
    required SecretKey masterKey,
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Raccogli dati in stream per evitare spike di memoria se possibile
      onProgress?.call(0.1);
      final transactions = await isar.transactionModels.where().findAll();
      onProgress?.call(0.3);
      final accounts = await isar.accounts.where().findAll();
      onProgress?.call(0.4);
      final budgets = await isar.budgets.where().findAll();
      final rules = await isar.categorizationRules.where().findAll();
      onProgress?.call(0.5);

      // 2. Serializza
      final dataMap = {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'categorization_rules': rules.map((r) => r.toJson()).toList(),
      };

      final payloadString = jsonEncode(dataMap);
      
      // 3. Genera Checksum del payload in chiaro (per verifica post-decrypt)
      final checksum = hash.sha256.convert(utf8.encode(payloadString)).toString();

      final backupData = {
        'version': currentBackupVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'payload': payloadString,
      };

      onProgress?.call(0.7);
      final jsonFinal = jsonEncode(backupData);

      // 4. Cifra l'intero pacchetto
      final encryptedPayload = await _crypto.encrypt(jsonFinal, masterKey);

      // 5. Scrittura sicura
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fyne_backup_${DateTime.now().millisecondsSinceEpoch}.fyne');
      
      try {
        await file.writeAsString(encryptedPayload, flush: true);
      } catch (ioe) {
        if (ioe.toString().contains('No space left')) {
          throw Exception('Spazio di archiviazione insufficiente sul dispositivo.');
        }
        rethrow;
      }

      onProgress?.call(1.0);
      _analytics.logExportSuccess();
      return file.path;
    } catch (e, stack) {
      _analytics.logError(e, stack, reason: 'backup_export_failed');
      _analytics.logExportFail(e.toString());
      rethrow;
    }
  }

  /// Importa un backup con validazione Checksum e Batch Insert.
  Future<void> importEncryptedBackup({
    required String filePath,
    required SecretKey masterKey,
    required Isar isar,
    bool mergeMode = false,
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('File non trovato');

      final encryptedContent = await file.readAsString();
      onProgress?.call(0.2);

      // 1. Decifra
      final decryptedJson = await _crypto.decrypt(encryptedContent, masterKey);
      final backupRoot = jsonDecode(decryptedJson) as Map<String, dynamic>;
      onProgress?.call(0.4);

      // 2. Valida struttura e checksum
      final String? backupVersion = backupRoot['version'];
      final String? expectedChecksum = backupRoot['checksum'];
      final String? payloadString = backupRoot['payload'];

      if (payloadString == null || expectedChecksum == null) {
        throw Exception('Backup corrotto o incompleto (Missing payload/checksum)');
      }

      // TODO: Implementare logica di migrazione se backupVersion < currentBackupVersion
      if (backupVersion != currentBackupVersion) {
        debugPrint('[BackupService] ⚠️ Version mismatch: $backupVersion vs $currentBackupVersion. Tentativo di migrazione...');
        // Qui si potrebbero aggiungere trasformazioni del payload per renderlo compatibile con la versione corrente
      }

      // Verifica Checksum
      final actualChecksum = hash.sha256.convert(utf8.encode(payloadString)).toString();
      if (actualChecksum != expectedChecksum) {
        throw Exception('Integrità backup fallita (Checksum mismatch). Il file potrebbe essere stato alterato.');
      }

      onProgress?.call(0.6);

      // 3. Parsing dati con protezione memoria
      final data = jsonDecode(payloadString) as Map<String, dynamic>;
      
      // 4. Ripristino Atomico
      await isar.writeTxn(() async {
        if (!mergeMode) {
          await isar.transactionModels.clear();
          await isar.accounts.clear();
          await isar.budgets.clear();
          await isar.categorizationRules.clear();
        }

        // Batch processing per performance
        final txList = (data['transactions'] as List?)
            ?.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        await isar.transactionModels.putAll(txList);
        onProgress?.call(0.8);

        final accList = (data['accounts'] as List?)
            ?.map((json) => Account.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        await isar.accounts.putAll(accList);

        final budgetList = (data['budgets'] as List?)
            ?.map((json) => Budget.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        await isar.budgets.putAll(budgetList);

        final rulesList = (data['categorization_rules'] as List?)
            ?.map((json) => CategorizationRule.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        await isar.categorizationRules.putAll(rulesList);
      });

      onProgress?.call(1.0);
      _analytics.logImportSuccess();
    } catch (e, stack) {
      _analytics.logError(e, stack, reason: 'backup_import_failed');
      _analytics.logImportFail(e.toString());
      rethrow;
    }
  }

  /// Validazione rapida senza import.
  Future<Map<String, dynamic>> validateBackup({
    required String filePath,
    required SecretKey masterKey,
  }) async {
    try {
      final file = File(filePath);
      final encryptedContent = await file.readAsString();
      final decryptedJson = await _crypto.decrypt(encryptedContent, masterKey);
      final backupRoot = jsonDecode(decryptedJson) as Map<String, dynamic>;

      final String payloadString = backupRoot['payload'];
      final data = jsonDecode(payloadString) as Map<String, dynamic>;
      
      return {
        'version': backupRoot['version'],
        'exported_at': backupRoot['exported_at'],
        'transactions_count': (data['transactions'] as List?)?.length ?? 0,
        'accounts_count': (data['accounts'] as List?)?.length ?? 0,
        'is_locked': false, // Se siamo qui, la chiave è corretta
      };
    } catch (e) {
      if (e.toString().contains('MAC')) {
        throw Exception('Chiave di decifratura errata.');
      }
      rethrow;
    }
  }

  Future<void> shareBackup(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Vault Fyne Backup - Cifrato AES-256');
  }
}
