import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:isar_community/isar.dart';
import 'package:crypto/crypto.dart' as hash;
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/categorization_rule.dart';
import 'crypto_service.dart';
import 'analytics_service.dart';

/// Servizio per Backup & Recovery cifrato - Hardened for Beta.
class BackupService {
  final CryptoService _crypto;
  final AnalyticsService _analytics = AnalyticsService();

  BackupService(this._crypto);
  static const String currentBackupVersion = '1.0.0';

  /// Esporta tutti i dati Isar in un file JSON cifrato con Checksum.
  Future<String> exportEncryptedBackup({
    required Isar isar,
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Scoped Keys are managed internally by CryptoService now.
      
      // 2. Raccogli dati in chunks
      onProgress?.call(0.1);
      final totalTransactions = await isar.transactionModels.count();
      final List<Map<String, dynamic>> txJsonList = [];
      const int chunkSize = 500;
      
      for (int i = 0; i < totalTransactions; i += chunkSize) {
        final chunk = await isar.transactionModels
            .where()
            .offset(i)
            .limit(chunkSize)
            .findAll();
        txJsonList.addAll(chunk.map((t) => t.toJson()));
        onProgress?.call(0.1 + (0.4 * (i + chunk.length) / totalTransactions));
      }

      final accounts = await isar.accounts.where().findAll();
      final budgets = await isar.budgets.where().findAll();
      final rules = await isar.categorizationRules.where().findAll();
      onProgress?.call(0.5);

      // 3. Serializza
      final dataMap = {
        'transactions': txJsonList,
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'categorization_rules': rules.map((r) => r.toJson()).toList(),
      };

      final payloadString = jsonEncode(dataMap);
      final checksum = hash.sha256.convert(utf8.encode(payloadString)).toString();

      final backupData = {
        'version': currentBackupVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'payload': payloadString,
      };

      onProgress?.call(0.7);
      final jsonFinal = jsonEncode(backupData);

      // 4. Cifra l'intero pacchetto con lo scope dedicato (Chiave gestita internamente)
      final encryptedPayload = await _crypto.encrypt(
        jsonFinal, 
        scope: EncryptionScope.backup,
      );

      // 5. Scrittura sicura
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fyne_backup_${DateTime.now().millisecondsSinceEpoch}.fyne');
      
      await file.writeAsString(encryptedPayload, flush: true);

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
    required Isar isar,
    bool mergeMode = false,
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('File non trovato');

      final encryptedContent = await file.readAsString();
      onProgress?.call(0.2);

      // 1. Decifra usando lo scope backup (Chiave gestita internamente)
      final decryptedJson = await _crypto.decrypt(
        encryptedContent, 
        scope: EncryptionScope.backup,
      );
      
      final backupRoot = jsonDecode(decryptedJson) as Map<String, dynamic>;
      onProgress?.call(0.4);

      // 2. Valida struttura e checksum
      final String? backupVersion = backupRoot['version'];
      final String? expectedChecksum = backupRoot['checksum'];
      final String? payloadString = backupRoot['payload'];

      if (payloadString == null || expectedChecksum == null) {
        throw Exception('Backup corrotto o incompleto');
      }

      final actualChecksum = hash.sha256.convert(utf8.encode(payloadString)).toString();
      if (actualChecksum != expectedChecksum) {
        throw Exception('Integrità backup fallita (Checksum mismatch)');
      }

      Map<String, dynamic> data;
      if (backupVersion != currentBackupVersion) {
        data = await _migratePayload(backupVersion ?? '0.0.0', jsonDecode(payloadString));
      } else {
        data = jsonDecode(payloadString) as Map<String, dynamic>;
      }

      onProgress?.call(0.6);
      
      await isar.writeTxn(() async {
        if (!mergeMode) {
          await isar.transactionModels.clear();
          await isar.accounts.clear();
          await isar.budgets.clear();
          await isar.categorizationRules.clear();
        }

        final txList = (data['transactions'] as List?)
            ?.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        await isar.transactionModels.putAll(txList);
        onProgress?.call(0.85);

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
  }) async {
    try {
      final file = File(filePath);
      final encryptedContent = await file.readAsString();
      
      final decryptedJson = await _crypto.decrypt(
        encryptedContent, 
        scope: EncryptionScope.backup,
      );
      
      final backupRoot = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final String payloadString = backupRoot['payload'];
      final data = jsonDecode(payloadString) as Map<String, dynamic>;
      
      return {
        'version': backupRoot['version'],
        'exported_at': backupRoot['exported_at'],
        'transactions_count': (data['transactions'] as List?)?.length ?? 0,
        'accounts_count': (data['accounts'] as List?)?.length ?? 0,
        'budgets_count': (data['budgets'] as List?)?.length ?? 0,
        'rules_count': (data['categorization_rules'] as List?)?.length ?? 0,
        'is_locked': false,
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

  /// Helper per migrare vecchi formati di backup alla versione corrente.
  /// Fail-fast: nessuna migrazione implicita — versioni sconosciute causerebbero
  /// silent data corruption se il payload venisse importato invariato.
  Future<Map<String, dynamic>> _migratePayload(String fromVersion, Map<String, dynamic> payload) async {
    // v1.0.0 → v1.0.0: nessuna migrazione necessaria (stesso schema)
    // Aggiungere qui i path di migrazione futuri, es:
    //   if (fromVersion == '0.9.0') return _migrate_0_9_to_1_0(payload);
    throw Exception(
      'Versione backup non supportata: $fromVersion. '
      'Versione attuale: $currentBackupVersion. '
      'Impossibile importare: il formato non è compatibile e la migrazione automatica non è definita.',
    );
  }
}

final backupServiceProvider = Provider((ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  return BackupService(crypto);
});
