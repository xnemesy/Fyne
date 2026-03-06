import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../services/categorization_service.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';

// ─── Stato del form ──────────────────────────────────────────────────────────

/// Rappresenta lo stato transitorio del form "Nuova Transazione".
/// I dati sensibili rimangono in chiaro SOLO in memoria durante la compilazione.
/// Al salvataggio vengono passati ai layer di cifratura (repository) e
/// subito dopo questa classe viene resettata/distrutta.
class TransactionFormState {
  final String rawAmount;
  final String rawDescription;
  final String rawCounterParty;

  // Conto selezionato dall'utente (id + nome decifrato per la UI)
  final Account? selectedAccount;

  // Categoria auto-selezionata dal keyword matching o manualmente
  final String? categoryName;
  final String? categoryUuid;

  // Data della transazione (default: oggi)
  final DateTime date;

  // true = Entrata (+), false = Uscita (-)
  final bool isIncome;

  // Stato salvataggio
  final bool isSaving;
  final String? error;

  const TransactionFormState({
    this.rawAmount = '',
    this.rawDescription = '',
    this.rawCounterParty = '',
    this.selectedAccount,
    this.categoryName,
    this.categoryUuid,
    required this.date,
    this.isIncome = false,
    this.isSaving = false,
    this.error,
  });

  TransactionFormState copyWith({
    String? rawAmount,
    String? rawDescription,
    String? rawCounterParty,
    Account? selectedAccount,
    bool clearAccount = false,
    String? categoryName,
    String? categoryUuid,
    DateTime? date,
    bool? isIncome,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TransactionFormState(
      rawAmount: rawAmount ?? this.rawAmount,
      rawDescription: rawDescription ?? this.rawDescription,
      rawCounterParty: rawCounterParty ?? this.rawCounterParty,
      selectedAccount: clearAccount ? null : (selectedAccount ?? this.selectedAccount),
      categoryName: categoryName ?? this.categoryName,
      categoryUuid: categoryUuid ?? this.categoryUuid,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Importo come double con segno (negativo per uscite).
  double get signedAmount {
    final abs = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
    return isIncome ? abs : -abs;
  }

  bool get isValid =>
      rawAmount.isNotEmpty &&
      (double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0) > 0 &&
      selectedAccount != null;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class TransactionFormNotifier extends Notifier<TransactionFormState> {
  static const Uuid _uuid = Uuid();

  @override
  TransactionFormState build() => TransactionFormState(date: DateTime.now());

  // --- Setter ----------------------------------------------------------------

  void setAmount(String value) {
    state = state.copyWith(rawAmount: value, clearError: true);
  }

  /// Aggiorna la descrizione e tenta il keyword matching automatico.
  /// Se la descrizione matcha un keyword noto, la categoria viene
  /// autoselezionata senza alcuna chiamata API/ML (No-AI policy).
  void setDescription(String value) {
    state = state.copyWith(rawDescription: value, clearError: true);
    _tryAutoCategoriztion(value);
  }

  void setCounterParty(String value) {
    state = state.copyWith(rawCounterParty: value);
  }

  void setAccount(Account? account) {
    state = state.copyWith(selectedAccount: account, clearError: true);
  }

  void setCategory(String name, String uuid) {
    state = state.copyWith(categoryName: name, categoryUuid: uuid);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void toggleDirection() {
    state = state.copyWith(isIncome: !state.isIncome, clearError: true);
  }

  // --- Keyword Matching (No-AI, deterministico) -----------------------------

  void _tryAutoCategoriztion(String description) {
    if (description.trim().length < 3) return;

    final categService = ref.read(categorizationServiceProvider);

    // Operazione sincrona via _keywordCategorize — nessun await, nessun AI
    final desc = description.toLowerCase();
    final matched = _matchKeywords(desc);
    if (matched != null) {
      final uuid = categService.getCategoryId(matched);
      state = state.copyWith(categoryName: matched, categoryUuid: uuid);
      debugPrint('[TX Form] 🏷️ Auto-categoria: "$matched" per "$description"');
    }
  }

  /// Mappa interna keyword → categoria (duplica le regole di CategorizationService
  /// per operare in modo sincrono nel form senza await).
  String? _matchKeywords(String desc) {
    // Regole ordinarie (stesso ordine di CategorizationService)
    if (_anyMatch(desc, ['esselunga', 'lidl', 'carrefour', 'coop', 'conad', 'pam', 'eurospin', 'supermercato', 'spesa'])) return 'Alimentari';
    if (_anyMatch(desc, ['netflix', 'spotify', 'disney', 'dazn', 'prime video', 'apple.com/bill'])) return 'Abbonamenti';
    if (_anyMatch(desc, ['amazon', 'zalando', 'ebay', 'temu', 'shein', 'ikea'])) return 'Shopping';
    if (_anyMatch(desc, ['mcdonald', 'burger king', 'kfc', 'poke', 'sushi', 'pizza', 'takeaway'])) return 'Fast Food';
    if (_anyMatch(desc, ['eni', 'shell', 'q8', 'benzina', 'trenitalia', 'italo', 'uber', 'taxi', 'atm'])) return 'Trasporti';
    if (_anyMatch(desc, ['virgin active', 'mcfit', 'palestra', 'gym', 'farmacia', 'decathlon', 'sport'])) return 'Wellness';
    if (_anyMatch(desc, ['tabacchi', 'sigarette', 'scommesse', 'casino'])) return 'Vizi';
    return null; // Nessun match → l'utente sceglie manualmente
  }

  bool _anyMatch(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // --- Salvataggio Zero-Knowledge -------------------------------------------

  /// Salva la transazione rispettando il contratto Zero-Knowledge:
  /// 1. Valida il form (conto obbligatorio)
  /// 2. Chiama TransactionProvider (che cifra via TransactionRepository)
  /// 3. Aggiorna il saldo del conto atomicamente (decrypt → ±delta → re-encrypt)
  Future<void> save() async {
    if (state.selectedAccount == null) {
      state = state.copyWith(error: 'Nessun conto selezionato');
      throw StateError('Nessun conto selezionato');
    }

    final amount = double.tryParse(state.rawAmount.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      state = state.copyWith(error: 'Inserisci un importo valido');
      return;
    }

    // Cattura i notifier prima di qualsiasi await (anti async-gap)
    final txNotifier      = ref.read(transactionsProvider.notifier);
    final accountNotifier = ref.read(accountsProvider.notifier);

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final now = DateTime.now();
      final txUuid = _uuid.v4();

      // Crea il modello scheletro (senza campi sensibili — vengono passati come raw)
      final txShell = TransactionModel(
        uuid: txUuid,
        accountId: state.selectedAccount!.id,
        bookingDate: state.date,
        currency: state.selectedAccount!.currency,
        encryptedAmount: '', // placeholder — verrà sovrascritto da repo.save()
        categoryUuid: state.categoryUuid,
        createdAt: now,
        updatedAt: now,
        encryptionVersion: 1,
      );

      // Delega la cifratura al TransactionRepository (AES-256-GCM + HMAC)
      await txNotifier.addTransaction(
            txShell,
            rawAmount: state.signedAmount.toStringAsFixed(2),
            rawDesc: state.rawDescription.isEmpty ? null : state.rawDescription,
            rawCounterParty:
                state.rawCounterParty.isEmpty ? null : state.rawCounterParty,
            rawCategoryName: state.categoryName,
          );

      // Aggiorna saldo conto atomicamente (decifra → ±delta → ri-cifra su Isar)
      await accountNotifier
          .applyTransactionDelta(state.selectedAccount!.id, state.signedAmount);

      debugPrint(
          '[TX] ✅ Transazione salvata uuid=$txUuid | delta=${state.signedAmount.toStringAsFixed(2)}');

      // Reset form dopo salvataggio riuscito
      state = TransactionFormState(date: DateTime.now());
    } catch (e) {
      debugPrint('[TX] ❌ Errore salvataggio: $e');
      state = state.copyWith(
        isSaving: false,
        error: e is StateError ? e.message : 'Errore nel salvataggio. Riprova.',
      );
      rethrow;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final transactionFormProvider =
    NotifierProvider<TransactionFormNotifier, TransactionFormState>(
  TransactionFormNotifier.new,
);
