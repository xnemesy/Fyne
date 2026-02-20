import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/services/crypto_service.dart';
import '../lib/services/key_rotation_service.dart';
import '../lib/models/transaction.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProvider();

  late Isar isar;
  late CryptoService crypto;
  late ProviderContainer container;
  
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [TransactionModelSchema],
      directory: '.',
    );
    crypto = CryptoService(storage: const FlutterSecureStorage());
    container = ProviderContainer();
  });

  tearDownAll(() async {
    await isar.close();
    container.dispose();
  });

  group('Key Rotation v2.5 Security Tests', () {
    
    test('1. Progressive Migration: v0 -> current (Atomic)', () async {
      await crypto.unlock('test-password', 'test-salt');
      
      const legacyVersion = 0;
      final encryptedAmount = await crypto.encrypt('100.0', scope: EncryptionScope.database, type: 'transaction_amount', version: legacyVersion);
      
      final legacyTx = TransactionModel(
        uuid: 'test-uuid-rotation',
        accountId: 'acc-1',
        bookingDate: DateTime.now(),
        currency: 'EUR',
        encryptedAmount: encryptedAmount,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        encryptionVersion: legacyVersion,
      );

      await isar.writeTxn(() => isar.transactionModels.put(legacyTx));

      final rotation = container.read(keyRotationProvider);
      
      final migrated = await rotation.migrateIfLegacy<TransactionModel>(
        recordUuid: legacyTx.uuid,
        currentVersion: legacyTx.encryptionVersion,
        decryptFn: (v) async {
          return await crypto.decrypt(legacyTx.encryptedAmount, scope: EncryptionScope.database, type: 'transaction_amount', version: v);
        },
        reEncryptAndUpdateFn: (plain, v) async {
          final newEnc = await crypto.encrypt(plain, scope: EncryptionScope.database, type: 'transaction_amount', version: v);
          return await isar.writeTxn(() async {
            final tx = await isar.transactionModels.where().uuidEqualTo(legacyTx.uuid).findFirst();
            final updated = TransactionModel(
              id: tx!.id,
              uuid: tx.uuid,
              accountId: tx.accountId,
              bookingDate: tx.bookingDate,
              currency: tx.currency,
              encryptedAmount: newEnc,
              updatedAt: DateTime.now(),
              createdAt: tx.createdAt,
              encryptionVersion: v,
            );
            await isar.transactionModels.put(updated);
            return updated;
          });
        }
      );

      expect(migrated, isNotNull);
      expect(migrated!.encryptionVersion, equals(CryptoService.currentCryptoVersion));
      
      final finalDec = await crypto.decrypt(
        migrated.encryptedAmount, 
        scope: EncryptionScope.database, 
        type: 'transaction_amount',
        version: CryptoService.currentCryptoVersion,
      );
      expect(finalDec, equals('100.0'));
    });

    test('2. Concurrency: Parallel reads trigger only ONE migration', () async {
       const legacyVersion = 0;
       final enc = await crypto.encrypt('50.0', scope: EncryptionScope.database, type: 'transaction_amount', version: legacyVersion);
       final tx = TransactionModel(
         uuid: 'race-uuid',
         accountId: 'acc-1',
         bookingDate: DateTime.now(),
         currency: 'EUR',
         encryptedAmount: enc,
         updatedAt: DateTime.now(),
         createdAt: DateTime.now(),
         encryptionVersion: legacyVersion,
       );
       await isar.writeTxn(() => isar.transactionModels.put(tx));

       final rotation = container.read(keyRotationProvider);

       int migrationCount = 0;

       Future<TransactionModel?> runMigration() async {
         return await rotation.migrateIfLegacy<TransactionModel>(
           recordUuid: tx.uuid,
           currentVersion: tx.encryptionVersion,
           decryptFn: (v) async => crypto.decrypt(tx.encryptedAmount, scope: EncryptionScope.database, version: v),
           reEncryptAndUpdateFn: (plain, v) async {
             migrationCount++;
             // Artificial delay to simulate processing and trigger race
             await Future.delayed(const Duration(milliseconds: 100));
             final newEnc = await crypto.encrypt(plain, scope: EncryptionScope.database, version: v);
             return await isar.writeTxn(() async {
                final existing = await isar.transactionModels.where().uuidEqualTo(tx.uuid).findFirst();
                final updated = TransactionModel(
                  id: existing!.id,
                  uuid: existing.uuid,
                  accountId: existing.accountId,
                  bookingDate: existing.bookingDate,
                  currency: existing.currency,
                  encryptedAmount: newEnc,
                  updatedAt: DateTime.now(),
                  createdAt: existing.createdAt,
                  encryptionVersion: v,
                );
                await isar.transactionModels.put(updated);
                return updated;
             });
           }
         );
       }

       await Future.wait([
         runMigration(),
         runMigration(),
       ]);

       expect(migrationCount, equals(1));
    });

    test('3. Integrity Failure: Tampered record aborts migration', () async {
       const legacyVersion = 0;
       final enc = await crypto.encrypt('critical-data', scope: EncryptionScope.database, type: 'record', version: legacyVersion);
       
       final decoded = base64.decode(enc);
       final tamperedBytes = Uint8List.fromList(decoded);
       // Tamper HMAC part (first 32 bytes)
       tamperedBytes[10] ^= 0xFF;
       final tampered = base64.encode(tamperedBytes);
       
       final tx = TransactionModel(
         uuid: 'tamper-uuid',
         accountId: 'acc-1',
         bookingDate: DateTime.now(),
         currency: 'EUR',
         encryptedAmount: tampered,
         updatedAt: DateTime.now(),
         createdAt: DateTime.now(),
         encryptionVersion: legacyVersion,
       );
       
       final rotation = container.read(keyRotationProvider);
       
       expect(() => rotation.migrateIfLegacy<TransactionModel>(
         recordUuid: tx.uuid,
         currentVersion: tx.encryptionVersion,
         decryptFn: (v) async => crypto.decrypt(tx.encryptedAmount, scope: EncryptionScope.database, version: v),
         reEncryptAndUpdateFn: (plain, v) async => tx,
       ), throwsException);
    });
  });
}
