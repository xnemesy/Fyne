# Lessons Learned & Technical Patterns

## Violazioni Trovate

### Sessioni 1–4 (storiche)

1. **Uso non valido di `const` su variabili statiche della classe Theme**
   - *Violazione:* `const FyneColors.amber`, `const FyneColors.forest`
   - *Motivo:* In `FyneColors`, i colori sono definiti come `static const Color`, ma istanziarli anteponendo un ulteriore `const` prima della classe (es. `const FyneColors.amber`) o usarli chiamando successivi metodi non-costanti (`const FyneColors.amber.withValues(...)`) risulta sintatticamente errato, producendo un `Invalid Constant Value` error.

2. **Costruttore di `Category` deprecato/invalido**
   - *Violazione:* Inizializzazione con parametri posizionali mancanti `Category(id, name)`.
   - *Motivo:* A seguito del refactoring, la classe `Category` in `categorization_service.dart` richiede parametri nominati e campi obbligatori (`id`, `name`, `icon`, `color`).

3. **Proprietà rimosse/deprecate nei pacchetti esterni (`fl_chart`)**
   - *Violazione:* Uso del parametro inesistente `tooltipRoundedRadius` in `LineTouchTooltipData`.
   - *Motivo:* La proprietà non è supportata in `fl_chart ^1.1.1`.

4. **Metodi non definiti referenziati nella UI**
   - *Violazione:* Interpolazione con `_buildFingerprint` assente in `dashboard_screen.dart`.
   - *Motivo:* Residuo di refactoring precedente non allineato.

### Sessione 5 — REGRESSION-FIXER (2026-03-06)

5. **Token colore inesistente `FyneColors.danger`**
   - *Violazione:* `FyneColors.danger` usato in `edit_account_sheet.dart` e `edit_budget_sheet.dart`.
   - *Motivo:* Il token non esiste in `fyne_theme.dart`. Il token corretto per gli stati di errore/pericolo è `FyneColors.rust` (`Color(0xFFB85450)`).
   - *Impatto:* 4 errori di compilazione in 2 file.

6. **`ref.read()` / `ref.watch()` dopo `await` (async-gap violation)**
   - *Violazione:* Chiamate a `ref.read(provider)` effettuate dopo una o più `await` all'interno di metodi `async` in `StateNotifier`.
   - *Motivo:* Dopo un `await`, il notifier potrebbe essere stato disposed o lo stato del provider potrebbe essere cambiato. Riverpod non garantisce la stabilità dei valori letti post-sospensione.
   - *File corretti:* `account_overview_provider`, `account_provider`, `scheduled_provider`, `cloud_backups_provider`, `sync_provider`, `transaction_form_provider`, `categorization_provider`.

---

## Pattern Corretti Approvati

### 1. Accesso a `FyneColors` (Regola Definitiva)

```dart
// ✅ CORRETTO — accesso diretto alla costante statica
color: FyneColors.amber
color: FyneColors.forest

// ✅ CORRETTO — metodi non-const chiamati senza prefisso const
color: FyneColors.forest.withValues(alpha: 0.15)
color: FyneColors.rust.withOpacity(0.4)

// ❌ VIETATO — const su espressione non-const
color: const FyneColors.amber
color: const FyneColors.forest.withValues(alpha: 0.15)
```

### 2. Mappa token colore — FyneColors (Reference Card)

| Semantica | Token corretto | Hex |
|-----------|---------------|-----|
| Primario / Azione principale | `FyneColors.forest` | `#4A6741` |
| Primario chiaro | `FyneColors.forestLight` | `#8FA68B` |
| Primario scuro | `FyneColors.forestDark` | `#2D4A3E` |
| Testo principale | `FyneColors.paper` | `#F5F5F0` |
| Sfondo principale | `FyneColors.ink` | `#1A1A1A` |
| Errore / Pericolo / Distruttivo | `FyneColors.rust` | `#B85450` |
| Accent caldo | `FyneColors.amber` | `#D4A574` |
| Oro / Premium | `FyneColors.gold` | `#C9A227` |

> ⚠️ `FyneColors.danger` **NON ESISTE**. Usare sempre `FyneColors.rust`.

### 3. Inizializzazione Modelli (`Category`)

```dart
// ✅ CORRETTO
Category(
  id: 'unique_id',
  name: 'Alimentari',
  icon: 'shopping_cart',
  color: '#4A6741',
)

// ❌ VIETATO — parametri posizionali / campi mancanti
Category(id, name)
```

### 4. Async-Gap Safety — Riverpod `StateNotifier`

```dart
// ✅ CORRETTO — tutte le letture ref prima di qualsiasi await
Future<void> myMethod() async {
  final masterKey   = ref.read(masterKeyProvider);
  final cryptoSvc   = ref.read(cryptoServiceProvider);
  final authStatus  = ref.read(authProvider).status;

  final isar = await ref.read(isarProvider.future); // await DOPO le letture
  if (!mounted) return;
  // usa masterKey, cryptoSvc, authStatus — già catturate in modo sicuro
}

// ❌ VIETATO — lettura dopo await
Future<void> myMethod() async {
  final isar = await ref.read(isarProvider.future);
  final masterKey = ref.read(masterKeyProvider); // ← VIOLAZIONE
}
```

### 5. Librerie UI — Upgrade Policy (`fl_chart`)

- Prima di usare un parametro di una libreria UI, verificare che esista nella versione installata (`pubspec.yaml`).
- Controllare il CHANGELOG del package per deprecazioni recenti.
- In caso di parametro inesistente: rimuovere senza sostituto piuttosto che lasciare un errore di compilazione.

### 6. Code Quality Generale

- `flutter analyze` deve restituire sempre **0 errori**.
- I warning nella whitelist pre-approvata (vedere `tasks/todo.md`) sono tollerati e non vanno modificati.
- Le 75 `info` nei file di test (`*_test.dart`) sono non-bloccanti.
- Qualsiasi interpolazione di stringa che referenzia un getter o metodo deve verificarne l'esistenza prima del commit.