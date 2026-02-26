import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyne_frontend/services/crypto_service.dart';

// ─── Test Zero-Knowledge Security ────────────────────────────────────────────
//
// Verifica il contratto ZK del layer di cifratura (CryptoService reale):
//  1. OPACITÀ: blob cifrati non contengono valori originali in chiaro
//  2. CORRETTEZZA: decrypt+chiave corretta restituisce valore originale
//  3. INTEGRITÀ HMAC: blob manomesso → VaultIntegrityException
//  4. AAD: type errato → errore AES-GCM authentication
//  5. KEYWORD MATCHING deterministico (No-AI)
//
// Setup: TestWidgetsFlutterBinding + mock del MethodChannel corretto
// (`plugins.it_nomads.com/flutter_secure_storage`) con mappa in-memory.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const _testPassword = 'fyne_test_password_2026';
  const _testSalt     = 'fyne_salt_16char'; // 16 chars per Argon2id nonce

  const _rawAmount       = '250.00';
  const _rawDescription  = 'Netflix abbonamento mensile';
  const _rawCounterParty = 'Netflix Inc.';

  // Stub in-memory del keychain nativo
  final Map<String, String> _fakeKeychain = {};

  late CryptoService crypto;

  setUpAll(() {
    // Mock del MethodChannel reale di FlutterSecureStorage
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'read':
          return _fakeKeychain[args?['key'] as String? ?? ''];
        case 'write':
          _fakeKeychain[args?['key'] as String] = args?['value'] as String;
          return null;
        case 'delete':
          _fakeKeychain.remove(args?['key'] as String?);
          return null;
        case 'readAll':
          return Map<String, String>.from(_fakeKeychain);
        case 'containsKey':
          return _fakeKeychain.containsKey(args?['key'] as String?);
        default:
          return null;
      }
    });
  });

  setUp(() async {
    _fakeKeychain.clear();
    const storage = FlutterSecureStorage();
    crypto = CryptoService(storage: storage);
    await crypto.unlock(_testPassword, _testSalt);
  });

  tearDown(() async {
    await crypto.wipe();
  });

  // ── Gruppo 1: Opacità dei blob cifrati ──────────────────────────────────

  group('1. Opacità ZK — blob cifrati non rivelano dati originali', () {
    test('encryptedAmount non contiene "250.00" in chiaro', () async {
      final encrypted = await crypto.encrypt(
        _rawAmount,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );

      final rawBytes    = base64.decode(encrypted);
      final rawString   = utf8.decode(rawBytes, allowMalformed: true);

      expect(encrypted.contains(_rawAmount), isFalse,
          reason: 'Il blob base64 non deve contenere "250.00"');
      expect(rawString.contains(_rawAmount), isFalse,
          reason: 'I byte grezzi non devono rivelare il valore');
      // HMAC(32) + AES-GCM payload → blob sempre > 50 bytes → > 67 chars base64
      expect(encrypted.length, greaterThan(50),
          reason: 'Il blob cifrato deve avere lunghezza strutturalmente significativa');

      debugPrint('✅ encryptedAmount opaco: ${encrypted.substring(0, 20)}... (${encrypted.length} chars)');
    });

    test('encryptedDescription non contiene "Netflix" in chiaro', () async {
      final encrypted = await crypto.encrypt(
        _rawDescription,
        scope: EncryptionScope.database,
        type: 'transaction_description',
      );

      final rawString = utf8.decode(base64.decode(encrypted), allowMalformed: true);

      expect(encrypted.contains('Netflix'), isFalse);
      expect(encrypted.contains(_rawDescription), isFalse);
      expect(rawString.contains('Netflix'), isFalse,
          reason: 'I byte grezzi non devono rivelare la descrizione');

      debugPrint('✅ encryptedDescription opaco: ${encrypted.substring(0, 20)}...');
    });

    test('encryptedCounterParty non contiene "Netflix Inc." in chiaro', () async {
      final encrypted = await crypto.encrypt(
        _rawCounterParty,
        scope: EncryptionScope.database,
        type: 'transaction_counterparty',
      );

      expect(encrypted.contains('Netflix Inc.'), isFalse);
      expect(base64.decode(encrypted).length, greaterThan(40));

      debugPrint('✅ encryptedCounterParty opaco: ${encrypted.substring(0, 20)}...');
    });

    test('IV random — due cifrature identiche producono blob diversi', () async {
      final enc1 = await crypto.encrypt(
        _rawAmount,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );
      final enc2 = await crypto.encrypt(
        _rawAmount,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );

      expect(enc1, isNot(equals(enc2)),
          reason: 'AES-GCM con IV randomico produce ciphertext diversi per ogni cifratura');

      debugPrint('✅ IV random: enc1[-8]=${enc1.substring(enc1.length - 8)} ≠ enc2[-8]=${enc2.substring(enc2.length - 8)}');
    });
  });

  // ── Gruppo 2: Correttezza decrypt + HMAC ────────────────────────────────

  group('2. Correttezza decrypt + HMAC valido', () {
    test('decrypt(encrypt(amount)) == valore originale esatto', () async {
      final encrypted = await crypto.encrypt(
        _rawAmount,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );
      final decrypted = await crypto.decrypt(
        encrypted,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );

      expect(decrypted, equals(_rawAmount));
      expect(double.tryParse(decrypted), equals(250.00));

      debugPrint('✅ Decrypt amount: "$decrypted"');
    });

    test('decrypt(encrypt(description)) == descrizione originale esatta', () async {
      final encrypted = await crypto.encrypt(
        _rawDescription,
        scope: EncryptionScope.database,
        type: 'transaction_description',
      );
      final decrypted = await crypto.decrypt(
        encrypted,
        scope: EncryptionScope.database,
        type: 'transaction_description',
      );

      expect(decrypted, equals(_rawDescription));

      debugPrint('✅ Decrypt description: "$decrypted"');
    });

    test('blob manomesso → VaultIntegrityException (HMAC mismatch)', () async {
      final encrypted = await crypto.encrypt(
        _rawAmount,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );

      // Bit-flip sull'ultimo byte del payload cifrato (dopo i 32 byte HMAC)
      final bytes = base64.decode(encrypted);
      bytes[bytes.length - 1] ^= 0xFF;
      final tampered = base64.encode(bytes);

      await expectLater(
        crypto.decrypt(
          tampered,
          scope: EncryptionScope.database,
          type: 'transaction_amount',
        ),
        throwsA(predicate<Object>(
          (e) => e.toString().contains('HMAC mismatch'),
          'deve lanciare VaultIntegrityException con messaggio HMAC mismatch',
        )),
      );

      debugPrint('✅ HMAC mismatch correttamente rilevato su blob manomesso');
    });

    test('type AAD errato → errore di decifratura (cross-contamination protection)', () async {
      // Cifra come transaction_amount, decifra come transaction_description
      // → AAD diverso → HMAC o AES-GCM authentication fallisce
      final encrypted = await crypto.encrypt(
        _rawAmount,
        scope: EncryptionScope.database,
        type: 'transaction_amount',
      );

      await expectLater(
        crypto.decrypt(
          encrypted,
          scope: EncryptionScope.database,
          type: 'transaction_description', // AAD intenzionalmente errato
        ),
        throwsA(isA<Exception>()),
      );

      debugPrint('✅ AAD mismatch correttamente rilevato (cross-contamination)');
    });

    test('vault bloccato → encrypt lancia "Vault locked"', () async {
      await crypto.wipe(); // blocco esplicito

      await expectLater(
        crypto.encrypt(
          _rawAmount,
          scope: EncryptionScope.database,
          type: 'transaction_amount',
        ),
        throwsA(predicate<Object>(
          (e) => e.toString().contains('Vault locked'),
          'deve contenere "Vault locked"',
        )),
      );

      debugPrint('✅ Vault locked: cifratura rifiutata correttamente');
    });
  });

  // ── Gruppo 3: Keyword matching deterministico (No-AI) ───────────────────

  group('3. Keyword matching — No-AI, deterministico', () {
    // Replica locale di _matchKeywords da TransactionFormNotifier
    String? matchKw(String description) {
      final d = description.toLowerCase();
      if (['esselunga','lidl','carrefour','coop','conad','pam','eurospin','supermercato','spesa'].any((k)=>d.contains(k))) return 'Alimentari';
      if (['netflix','spotify','disney','dazn','prime video','apple.com/bill'].any((k)=>d.contains(k))) return 'Abbonamenti';
      if (['amazon','zalando','ebay','temu','shein','ikea'].any((k)=>d.contains(k))) return 'Shopping';
      if (['mcdonald','burger king','kfc','poke','sushi','pizza','takeaway'].any((k)=>d.contains(k))) return 'Fast Food';
      if (['eni','shell','q8','benzina','trenitalia','italo','uber','taxi','atm'].any((k)=>d.contains(k))) return 'Trasporti';
      if (['virgin active','mcfit','palestra','gym','farmacia','decathlon','sport'].any((k)=>d.contains(k))) return 'Wellness';
      if (['tabacchi','sigarette','scommesse','casino'].any((k)=>d.contains(k))) return 'Vizi';
      return null;
    }

    test('Netflix → Abbonamenti',     () => expect(matchKw('Netflix subscription'), equals('Abbonamenti')));
    test('ESSELUNGA → Alimentari',    () => expect(matchKw('Pagamento ESSELUNGA SPA'), equals('Alimentari')));
    test('Amazon.com → Shopping',     () => expect(matchKw('Amazon.com order 123'), equals('Shopping')));
    test('Trenitalia → Trasporti',    () => expect(matchKw('Acquisto Trenitalia'), equals('Trasporti')));
    test('palestra → Wellness',       () => expect(matchKw('Mensile palestra'), equals('Wellness')));
    test('sconosciuto → null',        () => expect(matchKw('Pagamento generico'), isNull));
    test('case-insensitive',          () {
      expect(matchKw('NETFLIX'), equals('Abbonamenti'));
      expect(matchKw('Netflix'), equals('Abbonamenti'));
      expect(matchKw('netflix'), equals('Abbonamenti'));
    });
    test('no false positive su stringa breve', () => expect(matchKw('caf'), isNull));
  });
}
