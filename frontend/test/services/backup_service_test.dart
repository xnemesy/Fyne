import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fyne_frontend/services/backup_service.dart';
import 'package:fyne_frontend/services/crypto_service.dart';
import 'package:fyne_frontend/models/transaction.dart';
import 'package:fyne_frontend/models/account.dart';
import 'package:fyne_frontend/models/budget.dart';
import 'package:fyne_frontend/models/categorization_rule.dart';

void main() {
  late Isar isar;
  late CryptoService crypto;
  late BackupService backupService;
  late Directory testDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup test directory
    testDir = Directory.systemTemp.createTempSync('fyne_test_');

    // Mock path_provider e storage
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return testDir.path;
      }
      return null;
    });

    FlutterSecureStorage.setMockInitialValues({});
    
    // Setup Isar
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [
        TransactionModelSchema,
        AccountSchema,
        BudgetSchema,
        CategorizationRuleSchema,
      ],
      directory: testDir.path,
      name: 'test_backup',
    );

    // Setup Crypto e Backup Service
    crypto = CryptoService(storage: const FlutterSecureStorage());
    await crypto.unlock('testpass', 'testsalt');
    backupService = BackupService(crypto);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('BackupService - Export & Import', () {
    test('deve esportare backup cifrato con successo', () async {
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-1',
          accountId: 'acc-1',
          bookingDate: DateTime(2024, 1, 15),
          currency: 'EUR',
          encryptedAmount: 'encrypted_amount_data',
          encryptedDescription: 'encrypted_desc',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await isar.accounts.put(Account(
          id: 'acc-1',
          encryptedName: 'encrypted_conto',
          encryptedBalance: 'encrypted_1000',
          currency: 'EUR',
          type: AccountType.checking,
          updatedAt: DateTime.now(),
        ));
      });

      final filePath = await backupService.exportEncryptedBackup(isar: isar);

      expect(File(filePath).existsSync(), true);
      expect(filePath.endsWith('.fyne'), true);

      final fileSize = File(filePath).lengthSync();
      expect(fileSize, greaterThan(0));
    });

    test('deve validare backup prima dell\'import', () async {
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-validate',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: 'amount',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      });

      final exportPath = await backupService.exportEncryptedBackup(isar: isar);

      final info = await backupService.validateBackup(filePath: exportPath);

      expect(info['version'], BackupService.currentBackupVersion);
      expect(info['transactions_count'], 1);
      expect(info['is_locked'], false);
    });

    test('deve importare backup e ripristinare i dati', () async {
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-original',
          accountId: 'acc-1',
          bookingDate: DateTime(2024, 2, 10),
          currency: 'EUR',
          encryptedAmount: 'encrypted_500',
          encryptedDescription: 'Original transaction',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      });

      final backupPath = await backupService.exportEncryptedBackup(isar: isar);

      await isar.writeTxn(() async {
        await isar.transactionModels.clear();
      });

      var count = await isar.transactionModels.count();
      expect(count, 0);

      await backupService.importEncryptedBackup(
        filePath: backupPath,
        isar: isar,
      );

      count = await isar.transactionModels.count();
      expect(count, 1);

      final restored = await isar.transactionModels.where().findFirst();
      expect(restored!.uuid, 'tx-original');
    });

    test('deve rilevare backup corrotto (checksum mismatch)', () async {
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-1',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: 'amount',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      });

      final backupPath = await backupService.exportEncryptedBackup(isar: isar);

      final file = File(backupPath);
      final bytes = await file.readAsBytes();
      bytes[bytes.length ~/ 2] = (bytes[bytes.length ~/ 2] + 1) % 256;
      await file.writeAsBytes(bytes);

      expect(
        () => backupService.importEncryptedBackup(
          filePath: backupPath,
          isar: isar,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('deve fallire con chiave master errata', () async {
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-1',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: 'amount',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      });

      final backupPath = await backupService.exportEncryptedBackup(isar: isar);

      // Sostituisci il crypto service con uno inizializzato con password diversa
      final wrongCrypto = CryptoService(storage: const FlutterSecureStorage());
      await wrongCrypto.unlock('wrongpass', 'wrongsalt');
      final wrongBackupService = BackupService(wrongCrypto);

      expect(
        () => wrongBackupService.validateBackup(filePath: backupPath),
        throwsA(
          predicate((e) => e.toString().contains('MAC') || 
                          e.toString().contains('Chiave di decifratura errata')),
        ),
      );
    });
  });

  group('BackupService - Progress Tracking', () {
    test('deve tracciare il progresso dell\'export', () async {
      await isar.writeTxn(() async {
        for (int i = 0; i < 50; i++) {
          await isar.transactionModels.put(TransactionModel(
            uuid: 'tx-$i',
            accountId: 'acc-1',
            bookingDate: DateTime.now(),
            currency: 'EUR',
            encryptedAmount: 'amount_$i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      });

      final progressUpdates = <double>[];

      await backupService.exportEncryptedBackup(
        isar: isar,
        onProgress: (progress) {
          progressUpdates.add(progress);
        },
      );

      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.first, lessThan(1.0));
      expect(progressUpdates.last, equals(1.0));
    });
  });

  group('BackupService - Edge Cases', () {
    test('deve gestire database vuoto', () async {
      final backupPath = await backupService.exportEncryptedBackup(isar: isar);

      expect(File(backupPath).existsSync(), true);

      final info = await backupService.validateBackup(filePath: backupPath);

      expect(info['transactions_count'], 0);
      expect(info['accounts_count'], 0);
    });

    test('deve gestire grandi quantità di dati', () async {
      await isar.writeTxn(() async {
        for (int i = 0; i < 1000; i++) {
          await isar.transactionModels.put(TransactionModel(
            uuid: 'large-tx-$i',
            accountId: 'acc-1',
            bookingDate: DateTime(2024, 1, (i % 28) + 1),
            currency: 'EUR',
            encryptedAmount: 'amount_$i',
            encryptedDescription: 'Description for transaction $i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      });

      final backupPath = await backupService.exportEncryptedBackup(isar: isar);

      final info = await backupService.validateBackup(filePath: backupPath);

      expect(info['transactions_count'], 1000);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
