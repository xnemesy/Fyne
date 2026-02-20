import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fyne_frontend/models/transaction.dart';
import 'package:fyne_frontend/repositories/transaction_repository.dart';

void main() {
  late Isar isar;
  late SecretKey testMasterKey;
  late TransactionRepository repository;

  setUp(() async {
    // Setup Isar in-memory per i test
    isar = await Isar.open(
      [TransactionModelSchema],
      directory: '',
      name: 'test_transactions',
    );

    // Genera una chiave master di test
    final keyData = SecretKeyData.random(length: 32);
    testMasterKey = await keyData.extract();

    repository = TransactionRepository(isar, testMasterKey);
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
      // Crea 100 transazioni di test
      for (int i = 0; i < 100; i++) {
        await repository.save(
          TransactionModel(
            uuid: 'tx-$i',
            accountId: 'acc-1',
            bookingDate: DateTime(2024, 1, i % 28 + 1),
            currency: 'EUR',
            encryptedAmount: '',
            createdAt: DateTime.now(),
          ),
          rawAmount: '${i * 10}.00',
          rawDesc: 'Transaction $i',
        );
      }

      // Test prima pagina
      final page1 = await repository.getEncryptedPage(page: 0, pageSize: 20);
      expect(page1.length, 20);

      // Test decryption batch
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
      );

      await repository.save(transaction, rawAmount: '100.00');

      // Crea repository con chiave diversa
      final wrongKey = await SecretKeyData.random(length: 32).extract();
      final wrongRepo = TransactionRepository(isar, wrongKey);

      final result = await wrongRepo.getByUuid('test-fail');
      expect(result, isNotNull);
      expect(result!.amount, isNull); // Decryption fallita
    });

    test('deve eliminare correttamente una transazione', () async {
      final transaction = TransactionModel(
        uuid: 'to-delete',
        accountId: 'acc-1',
        bookingDate: DateTime.now(),
        currency: 'EUR',
        encryptedAmount: '',
        createdAt: DateTime.now(),
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
        ),
        rawAmount: '123.456789',
      );

      final result = await repository.getByUuid('precise');
      expect(result!.amount, closeTo(123.456789, 0.000001));
    });
  });
}
