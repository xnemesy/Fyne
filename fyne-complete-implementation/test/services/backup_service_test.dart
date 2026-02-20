import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fyne_frontend/services/backup_service.dart';
import 'package:fyne_frontend/models/transaction.dart';
import 'package:fyne_frontend/models/account.dart';

void main() {
  late Isar isar;
  late SecretKey testMasterKey;
  late BackupService backupService;
  late Directory testDir;

  setUp(() async {
    // Setup test directory
    testDir = Directory.systemTemp.createTempSync('fyne_test_');

    // Setup Isar
    isar = await Isar.open(
      [TransactionModelSchema, AccountSchema],
      directory: testDir.path,
      name: 'test_backup',
    );

    // Generate master key
    final keyData = SecretKeyData.random(length: 32);
    testMasterKey = await keyData.extract();

    backupService = BackupService();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('BackupService - Export & Import', () {
    test('deve esportare backup cifrato con successo', () async {
      // Popola database con dati di test
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-1',
          accountId: 'acc-1',
          bookingDate: DateTime(2024, 1, 15),
          currency: 'EUR',
          encryptedAmount: 'encrypted_amount_data',
          encryptedDescription: 'encrypted_desc',
          createdAt: DateTime.now(),
        ));

        await isar.accounts.put(Account(
          id: 'acc-1',
          encryptedName: 'encrypted_conto',
          encryptedBalance: 'encrypted_1000',
          currency: 'EUR',
          type: AccountType.checking,
        ));
      });

      // Export
      final filePath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      expect(File(filePath).existsSync(), true);
      expect(filePath.endsWith('.fyne'), true);

      // Verifica dimensione file > 0
      final fileSize = File(filePath).lengthSync();
      expect(fileSize, greaterThan(0));
    });

    test('deve validare backup prima dell\'import', () async {
      // Crea e esporta backup
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-validate',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: 'amount',
          createdAt: DateTime.now(),
        ));
      });

      final exportPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      // Valida
      final info = await backupService.validateBackup(
        filePath: exportPath,
        masterKey: testMasterKey,
      );

      expect(info['version'], BackupService.currentBackupVersion);
      expect(info['transactions_count'], 1);
      expect(info['is_locked'], false);
    });

    test('deve importare backup e ripristinare i dati', () async {
      // Popola database originale
      await isar.writeTxn(() async {
        await isar.transactionModels.put(TransactionModel(
          uuid: 'tx-original',
          accountId: 'acc-1',
          bookingDate: DateTime(2024, 2, 10),
          currency: 'EUR',
          encryptedAmount: 'encrypted_500',
          encryptedDescription: 'Original transaction',
          createdAt: DateTime.now(),
        ));
      });

      // Export
      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      // Cancella database
      await isar.writeTxn(() async {
        await isar.transactionModels.clear();
      });

      var count = await isar.transactionModels.count();
      expect(count, 0);

      // Import backup
      await backupService.importEncryptedBackup(
        filePath: backupPath,
        masterKey: testMasterKey,
        isar: isar,
      );

      // Verifica ripristino
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
        ));
      });

      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      // Corrompi il file (modifica alcuni bytes)
      final file = File(backupPath);
      final bytes = await file.readAsBytes();
      bytes[bytes.length ~/ 2] = (bytes[bytes.length ~/ 2] + 1) % 256;
      await file.writeAsBytes(bytes);

      // L'import dovrebbe fallire con errore MAC o decrypt
      expect(
        () => backupService.importEncryptedBackup(
          filePath: backupPath,
          masterKey: testMasterKey,
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
        ));
      });

      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      // Usa chiave diversa per l'import
      final wrongKey = await SecretKeyData.random(length: 32).extract();

      expect(
        () => backupService.validateBackup(
          filePath: backupPath,
          masterKey: wrongKey,
        ),
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
          ));
        }
      });

      final progressUpdates = <double>[];

      await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
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
      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      expect(File(backupPath).existsSync(), true);

      final info = await backupService.validateBackup(
        filePath: backupPath,
        masterKey: testMasterKey,
      );

      expect(info['transactions_count'], 0);
      expect(info['accounts_count'], 0);
    });

    test('deve gestire grandi quantità di dati', () async {
      // Popola con 1000 transazioni
      await isar.writeTxn(() async {
        for (int i = 0; i < 1000; i++) {
          await isar.transactionModels.put(TransactionModel(
            uuid: 'large-tx-$i',
            accountId: 'acc-1',
            bookingDate: DateTime(2024, 1, (i % 28) + 1),
            currency: 'EUR',
            encryptedAmount: 'amount_$i',
            encryptedDescription: 'Description for transaction $i with some extra text to make it realistic',
            createdAt: DateTime.now(),
          ));
        }
      });

      final backupPath = await backupService.exportEncryptedBackup(
        isar: isar,
        masterKey: testMasterKey,
      );

      final info = await backupService.validateBackup(
        filePath: backupPath,
        masterKey: testMasterKey,
      );

      expect(info['transactions_count'], 1000);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
