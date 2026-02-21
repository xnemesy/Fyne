import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fyne_frontend/models/transaction.dart';
import 'package:fyne_frontend/data/repositories/transaction_repository.dart';
import 'package:fyne_frontend/services/crypto_service.dart';
import 'package:fyne_frontend/services/key_rotation_service.dart';

class FakeKeyRotationService implements KeyRotationService {
  @override
  Future<T?> migrateIfLegacy<T>({
    required String recordUuid,
    required int currentVersion,
    required Future<String> Function(int version) decryptFn,
    required Future<T> Function(String plainText, int newVersion) reEncryptAndUpdateFn,
  }) async {
    return null;
  }
  @override
  void setMigrationEnabled(bool enabled) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Isar isar;
  late CryptoService crypto;
  late FakeKeyRotationService rotation;
  late TransactionRepository repository;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [TransactionModelSchema],
      directory: '',
      name: 'test_transactions',
    );

    crypto = CryptoService(storage: const FlutterSecureStorage());
    await crypto.unlock('testpass', 'testsalt');
    rotation = FakeKeyRotationService();

    repository = TransactionRepository(isar, crypto, rotation);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('TransactionRepository - Encryption & Decryption', () {
    test('deve cifrare e salvare una transazione correttamente', () async {
      final transaction = TransactionModel(
        uuid: 'test-uuid-001',
        accountId: 'acc-123',
        bookingDate: DateTime(2024, 1, 15),
        currency: 'EUR',
        encryptedAmount: '', // Verrà cifrato dal repository
        categoryUuid: 'cat-food',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.save(
        transaction,
        rawAmount: '150.50',
        rawDesc: 'Spesa al supermercato',
        rawCounterParty: 'Esselunga',
        rawCategoryName: 'Alimentari',
      );

      final saved = await repository.getByUuid('test-uuid-001');
      expect(saved, isNotNull);
      expect(saved!.uuid, 'test-uuid-001');
      expect(saved.amount, 150.50);
      expect(saved.description, 'Spesa al supermercato');
      expect(saved.counterParty, 'Esselunga');
      expect(saved.categoryName, 'Alimentari');
    });

    test('deve gestire correttamente la paginazione cifrata', () async {
      for (int i = 0; i < 100; i++) {
        await repository.save(
          TransactionModel(
            uuid: 'tx-$i',
            accountId: 'acc-1',
            bookingDate: DateTime(2024, 1, i % 28 + 1),
            currency: 'EUR',
            encryptedAmount: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          rawAmount: '${i * 10}.00',
          rawDesc: 'Transaction $i',
        );
      }

      final page1 = await repository.getEncryptedPage(page: 0, pageSize: 20);
      expect(page1.length, 20);

      final decryptedSummaries = await repository.decryptPageForList(page1);
      expect(decryptedSummaries.length, 20);
      expect(decryptedSummaries.first.description, isNotNull);
    });

    test('deve fallire con chiave master errata', () async {
      final transaction = TransactionModel(
        uuid: 'test-fail',
        accountId: 'acc-1',
        bookingDate: DateTime.now(),
        currency: 'EUR',
        encryptedAmount: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.save(transaction, rawAmount: '100.00');

      // Crea repository con chiave diversa (simulato chiudendo e riaprendo con altra pass)
      final wrongCrypto = CryptoService(storage: const FlutterSecureStorage());
      await wrongCrypto.unlock('wrongpass', 'wrongsalt');
      final wrongRepo = TransactionRepository(isar, wrongCrypto, rotation);

      expect(
        () async => await wrongRepo.getByUuid('test-fail'),
        throwsA(isA<Exception>()),
      );
    });

    test('deve eliminare correttamente una transazione', () async {
      final transaction = TransactionModel(
        uuid: 'to-delete',
        accountId: 'acc-1',
        bookingDate: DateTime.now(),
        currency: 'EUR',
        encryptedAmount: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.save(transaction, rawAmount: '50.00');
      
      var saved = await repository.getByUuid('to-delete');
      expect(saved, isNotNull);

      await repository.deleteByUuid('to-delete');
      
      saved = await repository.getByUuid('to-delete');
      expect(saved, isNull);
    });
  });

  group('TransactionRepository - Edge Cases', () {
    test('deve gestire importi negativi (uscite)', () async {
      await repository.save(
        TransactionModel(
          uuid: 'negative',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        rawAmount: '-500.75',
      );

      final result = await repository.getByUuid('negative');
      expect(result!.amount, -500.75);
    });

    test('deve gestire caratteri speciali nella descrizione', () async {
      const specialDesc = 'Caffè ☕ & Brioche 🥐 - "Best" café';
      
      await repository.save(
        TransactionModel(
          uuid: 'special',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        rawAmount: '5.50',
        rawDesc: specialDesc,
      );

      final result = await repository.getByUuid('special');
      expect(result!.description, specialDesc);
    });

    test('deve gestire importi decimali con alta precisione', () async {
      await repository.save(
        TransactionModel(
          uuid: 'precise',
          accountId: 'acc-1',
          bookingDate: DateTime.now(),
          currency: 'EUR',
          encryptedAmount: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        rawAmount: '123.456789',
      );

      final result = await repository.getByUuid('precise');
      expect(result!.amount, closeTo(123.456789, 0.000001));
    });
  });
}
