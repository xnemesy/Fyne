# Skeleton Loading — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Sostituire tutti i `CircularProgressIndicator` di lista/contenuto con skeleton shimmer animati nelle 4 schermate principali di Fyne.

**Architecture:** Si estende il file `fyne_shimmer.dart` con due nuovi widget (`FyneAccountShimmer`, `FyneInsightsShimmer`), poi si aggiornano le 4 schermate che li consumano. Nessun nuovo file di schermata, nessuna modifica ai provider.

**Tech Stack:** Flutter 3.x, `shimmer: ^3.0.0` (già in `pubspec.yaml`), Riverpod StateNotifierProvider (legacy), Dark Mode forzata.

---

## Contesto Rapido

Il pacchetto `shimmer` è già installato. I widget existenti:
- `FyneShimmer` — rettangolo shimmer parametrico (`width`, `height`, `borderRadius`)
- `FyneTransactionShimmer` — riga transazione shimmer pronta (icona + 2 linee + importo)

Tutti i file sono in `frontend/lib/`.

---

### Task 1: `FyneAccountShimmer` — placeholder riga account

**File:**
- Modify: `frontend/lib/presentation/widgets/fyne_shimmer.dart` (append dopo riga 61)

**Step 1: Aggiungi `FyneAccountShimmer` in fondo al file**

```dart
/// Placeholder shimmer per una riga account nel WalletScreen.
/// Morfologicamente identico a `_buildAccountRow` in wallet_screen.dart:
/// icona circolare 40×40 | nome + tipo conto | importo a destra.
class FyneAccountShimmer extends StatelessWidget {
  const FyneAccountShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Icona circolare (come typeIcon in _buildAccountRow)
          const FyneShimmer(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome del conto
                FyneShimmer(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: 14,
                ),
                const SizedBox(height: 6),
                // Tipo/gruppo conto
                FyneShimmer(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: 12,
                ),
              ],
            ),
          ),
          // Importo a destra
          const FyneShimmer(width: 64, height: 16),
        ],
      ),
    );
  }
}
```

**Step 2: Verifica visiva (hot reload)**

Aggiungi temporaneamente `FyneAccountShimmer()` come primo child di qualsiasi Column visibile nell'app, fai hot reload, verifica che il layout corrisponda morfologicamente a una riga account nel WalletScreen.

Rimuovi il widget di test prima del commit.

**Step 3: Commit**

```bash
git add frontend/lib/presentation/widgets/fyne_shimmer.dart
git commit -m "feat: aggiunge FyneAccountShimmer per skeleton loading conti"
```

---

### Task 2: `FyneInsightsShimmer` — placeholder sezione analisi

**File:**
- Modify: `frontend/lib/presentation/widgets/fyne_shimmer.dart` (append dopo FyneAccountShimmer)

**Step 1: Aggiungi `FyneInsightsShimmer` in fondo al file**

```dart
/// Placeholder shimmer per la sezione Rapporti in InsightsScreen.
/// Struttura:
///   - Rettangolo alto 180px → placeholder grafico NetWorth
///   - Linea larga → placeholder numero patrimonio (testo grande)
///   - 3 pillole orizzontali → placeholder categorie
class FyneInsightsShimmer extends StatelessWidget {
  const FyneInsightsShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder numero patrimonio (Lora 40px)
          FyneShimmer(width: width * 0.55, height: 40),
          const SizedBox(height: 8),
          FyneShimmer(width: width * 0.25, height: 14),
          const SizedBox(height: 28),

          // Placeholder grafico a linee
          FyneShimmer(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),

          // Placeholder 3 pillole categoria
          Row(
            children: [
              FyneShimmer(width: width * 0.22, height: 32, borderRadius: BorderRadius.circular(16)),
              const SizedBox(width: 8),
              FyneShimmer(width: width * 0.22, height: 32, borderRadius: BorderRadius.circular(16)),
              const SizedBox(width: 8),
              FyneShimmer(width: width * 0.22, height: 32, borderRadius: BorderRadius.circular(16)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add frontend/lib/presentation/widgets/fyne_shimmer.dart
git commit -m "feat: aggiunge FyneInsightsShimmer per skeleton loading analisi"
```

---

### Task 3: TransactionsScreen — loading iniziale

**File:**
- Modify: `frontend/lib/presentation/screens/transactions_screen.dart:151`

**Step 1: Aggiorna l'import**

In cima al file (dopo gli import esistenti), aggiungi se non presente:

```dart
import '../widgets/fyne_shimmer.dart';
```

**Step 2: Sostituisci il ramo `loading:` in `transactionsAsync.when`**

Trova (riga ~151):
```dart
loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
```

Sostituisci con:
```dart
loading: () => ListView.builder(
  physics: const NeverScrollableScrollPhysics(),
  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
  itemCount: 8,
  itemBuilder: (_, __) => const FyneTransactionShimmer(),
),
```

**Nota:** `NeverScrollableScrollPhysics` perché la lista shimmer è dentro un `Expanded` e non deve scorrere autonomamente.

**Step 3: Verifica visiva**

Fai hot reload. Naviga sulla tab "Movimenti". Se i dati sono già caricati, prova a osservare il loading forzando un `refresh()`. Devi vedere 8 righe shimmer invece dello spinner.

**Step 4: Commit**

```bash
git add frontend/lib/presentation/screens/transactions_screen.dart
git commit -m "feat: sostituisce spinner loading con skeleton in TransactionsScreen"
```

---

### Task 4: TransactionsScreen — paginazione "carica altri"

**File:**
- Modify: `frontend/lib/presentation/screens/transactions_screen.dart:88-95`

**Step 1: Sostituisci il loader di paginazione**

Trova (righe 90-95):
```dart
if (index == visibleSummaries.length) {
  return const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
  );
}
```

Sostituisci con:
```dart
if (index == visibleSummaries.length) {
  // 3 righe shimmer durante il caricamento incrementale in fondo alla lista
  return const Column(
    children: [
      FyneTransactionShimmer(),
      FyneTransactionShimmer(),
      FyneTransactionShimmer(),
    ],
  );
}
```

**Step 2: Verifica visiva**

Per testare la paginazione: carica la schermata con molte transazioni e scrolla fino in fondo per attivare `loadMore()`. Devi vedere 3 righe shimmer invece dello spinner rotante.

**Step 3: Commit**

```bash
git add frontend/lib/presentation/screens/transactions_screen.dart
git commit -m "feat: sostituisce spinner paginazione con skeleton in TransactionsScreen"
```

---

### Task 5: WalletScreen — loading lista conti

**File:**
- Modify: `frontend/lib/presentation/screens/wallet_screen.dart:240-242`

**Step 1: Aggiorna l'import**

In cima al file, aggiungi se non presente:

```dart
import '../widgets/fyne_shimmer.dart';
```

**Step 2: Sostituisci il ramo `loading:` in `accountsAsync.when`**

Trova (righe 240-242):
```dart
loading: () => const SliverFillRemaining(
  child: Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
),
```

Sostituisci con:
```dart
loading: () => SliverList(
  delegate: SliverChildBuilderDelegate(
    (_, __) => const FyneAccountShimmer(),
    childCount: 4,
  ),
),
```

**Nota:** Si usa `SliverList` invece di `SliverFillRemaining` perché il WalletScreen usa `CustomScrollView` e i figli devono essere Sliver. `SliverFillRemaining` riempiva tutto lo schermo con un singolo spinner — le 4 righe shimmer sono visivamente più corrette e coerenti con la struttura reale.

**Step 3: Verifica visiva**

Naviga sulla tab "Conti". Devi vedere 4 righe account shimmer invece dello spinner centrato.

**Step 4: Commit**

```bash
git add frontend/lib/presentation/screens/wallet_screen.dart
git commit -m "feat: sostituisce spinner loading con skeleton in WalletScreen"
```

---

### Task 6: InsightsScreen — loading sezione analisi

**File:**
- Modify: `frontend/lib/presentation/screens/insights_screen.dart:79-85`

**Step 1: Aggiorna l'import**

In cima al file, aggiungi se non presente:

```dart
import '../widgets/fyne_shimmer.dart';
```

**Step 2: Sostituisci il ramo `insightsState.isLoading`**

Trova (righe 79-85):
```dart
child: insightsState.isLoading
    ? const SizedBox(
        height: 300,
        child: Center(
            child: CircularProgressIndicator(
                color: Color(0xFF4A6741))),
      )
    : (insightsState.netWorth == 0 && ...
```

Sostituisci la parte del ramo `isLoading` — mantieni invariato il resto del ternario:
```dart
child: insightsState.isLoading
    ? const FyneInsightsShimmer()
    : (insightsState.netWorth == 0 && ...
```

**Step 3: Verifica visiva**

Naviga sulla tab "Analisi". Durante il caricamento devi vedere il placeholder grafico + numero patrimonio + pillole categorie invece dello spinner 300px.

**Step 4: Commit**

```bash
git add frontend/lib/presentation/screens/insights_screen.dart
git commit -m "feat: sostituisce spinner loading con skeleton in InsightsScreen"
```

---

### Task 7: DashboardScreen — rimozione guard `isLoading`

**File:**
- Modify: `frontend/lib/presentation/screens/dashboard_screen.dart:88-100`

**Razionale:** `AccountCarousel` (righe 182-187) e `BalanceChart` (righe 191-195) gestiscono già il proprio stato shimmer interno quando `accountOverviewProvider` o `insightsProvider` sono in loading. Il guard `if (state.isLoading) return Center(spinner)` blocca l'intera schermata prima che questi widget possano mostrare i loro skeleton. Rimuovendolo, la schermata si renderizza subito e i widget figli fanno il loro lavoro.

**Step 1: Rimuovi il guard di loading**

Trova (righe 88-100):
```dart
Widget _buildHomeTab(AccountOverviewState state) {
  if (state.isLoading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Caricamento dati...'),
        ],
      ),
    );
  }

  if (state.error != null) {
```

Sostituisci rimuovendo solo il blocco `isLoading` (mantieni il blocco error invariato):
```dart
Widget _buildHomeTab(AccountOverviewState state) {
  if (state.error != null) {
```

**Step 2: Verifica visiva**

Naviga sulla tab "Home". Devi vedere immediatamente la struttura della schermata (header, card patrimonio, carousel, grafico) con i widget shimmer al loro posto durante il caricamento — non più uno spinner centrato a schermo pieno.

**Step 3: Commit**

```bash
git add frontend/lib/presentation/screens/dashboard_screen.dart
git commit -m "feat: rimuove guard isLoading in DashboardScreen, skeleton gestiti dai widget figli"
```

---

### Task 8: Verifica finale e cleanup

**Step 1: Cerca spinner rimasti nelle 5 schermate**

```bash
grep -n "CircularProgressIndicator" \
  frontend/lib/presentation/screens/transactions_screen.dart \
  frontend/lib/presentation/screens/wallet_screen.dart \
  frontend/lib/presentation/screens/insights_screen.dart \
  frontend/lib/presentation/screens/dashboard_screen.dart \
  frontend/lib/presentation/widgets/fyne_shimmer.dart
```

**Risultato atteso:** nessun match.

**Step 2: Build di verifica**

```bash
cd frontend && flutter analyze --no-fatal-infos
```

**Risultato atteso:** 0 errori. Eventuali warning preesistenti sono accettabili.

**Step 3: Verifica visiva completa (checklist)**

- [ ] Tab Home: schermata si renderizza subito, AccountCarousel shimmer visibile
- [ ] Tab Home: dopo la decrittazione, i dati compaiono senza scatto visivo
- [ ] Tab Conti: 4 righe account shimmer durante loading, nessun spinner centrato
- [ ] Tab Analisi: FyneInsightsShimmer durante loading, nessun rettangolo bianco con spinner
- [ ] Tab Movimenti: 8 righe transazione shimmer durante loading iniziale
- [ ] Tab Movimenti: scroll fino in fondo → 3 righe shimmer durante paginazione
- [ ] Button spinner in fogli modali (Aggiungi transazione, Aggiungi conto, ecc.) → invariati
- [ ] Dark mode: shimmer visibili (bianco trasparente su sfondo scuro)

**Step 4: Commit finale**

```bash
git add -A
git commit -m "chore: verifica skeleton loading — tutti i CircularProgressIndicator di lista rimossi"
```
