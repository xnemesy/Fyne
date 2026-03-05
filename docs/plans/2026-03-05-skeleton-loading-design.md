# Design: Skeleton Loading — Fyne
**Data:** 2026-03-05
**Autore:** Claude Code

---

## Problema

L'app mostra `CircularProgressIndicator` durante la decrittazione asincrona (Isolate) di centinaia di record Isar. In 4 schermate principali, questo blocca visivamente l'intera UI e tradisce il design premium dell'app.

## Obiettivo

Sostituire i spinner di lista/contenuto con **skeleton loading** — placeholder animati che rispecchiano la struttura reale dell'interfaccia, permettendo all'utente di orientarsi spazialmente anche prima che i dati siano pronti.

---

## Scelte di Design

### 1. Approccio scelto
**Riuso del sistema shimmer esistente** (`shimmer: ^3.0.0` già in `pubspec.yaml`, `FyneShimmer` + `FyneTransactionShimmer` già in `fyne_shimmer.dart`). Si aggiungono due nuovi widget nello stesso file per coprire i contesti mancanti.

### 2. Spinner esclusi dalla modifica
I seguenti spinner rimangono invariati perché semanticamente corretti (azione dell'utente in corso):
- Button spinner (salvataggio conto, transazione, budget)
- Lock screen unlock animation
- Login/Onboarding/Recovery
- Backup/Restore operations
- Transaction detail loading

---

## Componenti da Creare

### `FyneAccountShimmer` (in `fyne_shimmer.dart`)
Simula una riga account nel WalletScreen.

```
Struttura morfologica:
┌─────────────────────────────────────────────┐
│  [●40]  [──── 120px ────]     [──── 60px ──]│
│         [──── 80px  ────]                    │
└─────────────────────────────────────────────┘
```

- Icona circolare `40×40` + padding
- 2 linee testo (nome + tipo conto)
- Importo a destra
- Stessa struttura di `_buildAccountRow` in `wallet_screen.dart`

### `FyneInsightsShimmer` (in `fyne_shimmer.dart`)
Simula il blocco "Rapporti" in InsightsScreen durante il caricamento.

```
Struttura morfologica:
┌──────────────────────────────────────────────┐
│ [──────────────── 180px alto ───────────────]│  ← placeholder grafico
│ [──────────── 140px ────────────]            │  ← numero patrimonio
│ [──── 60px ──] [──── 60px ──] [──── 60px ──]│  ← pillole categoria
└──────────────────────────────────────────────┘
```

---

## Integrazione nelle Schermate

### `transactions_screen.dart`

**Loading iniziale** (`transactionsNotifierProvider.when(loading:)`):
- Rimuovi `Center(CircularProgressIndicator)`
- Sostituisci con `ListView` non scrollabile contenente 8× `FyneTransactionShimmer`

**Paginazione** (item finale quando `notifier.hasMore`):
- Rimuovi `CircularProgressIndicator` 24px
- Sostituisci con 3× `FyneTransactionShimmer` consecutive

### `wallet_screen.dart`

**Loading lista conti** (`accountsAsync.when(loading:)`):
- Rimuovi `SliverFillRemaining(child: CircularProgressIndicator)`
- Sostituisci con `SliverList` contenente 4× `FyneAccountShimmer`

### `insights_screen.dart`

**Loading sezione analisi** (`insightsState.isLoading`):
- Rimuovi `SizedBox(height:300, child: CircularProgressIndicator)`
- Sostituisci con `FyneInsightsShimmer` inline (stesso `FyneAnimations.slideUp` wrapper)

### `dashboard_screen.dart`

**Loading home tab** (`state.isLoading` guard in `_buildHomeTab`):
- Rimuovi il branch `if (state.isLoading) return Center(CircularProgressIndicator)`
- La schermata mostra direttamente la struttura sliver; `AccountCarousel` e `BalanceChart` gestiscono autonomamente il proprio stato shimmer interno

---

## Specifiche Visive

| Proprietà | Valore |
|---|---|
| Base color (dark) | `Colors.white10` (già in `FyneShimmer`) |
| Highlight color (dark) | `Colors.white24` (già in `FyneShimmer`) |
| Border radius standard | `BorderRadius.circular(8)` (default `FyneShimmer`) |
| Border radius icone circolari | `BorderRadius.circular(20)` |
| Dimensione icona account | `40×40` |
| Altezza riga account | `~72px` |
| Altezza placeholder grafico | `180px` |
| N. righe transazione (init) | `8` |
| N. righe transazione (paginazione) | `3` |
| N. righe account | `4` |

---

## File Coinvolti

| File | Tipo modifica |
|---|---|
| `frontend/lib/presentation/widgets/fyne_shimmer.dart` | Aggiunta `FyneAccountShimmer`, `FyneInsightsShimmer` |
| `frontend/lib/presentation/screens/transactions_screen.dart` | Sostituzione 2 spinner |
| `frontend/lib/presentation/screens/wallet_screen.dart` | Sostituzione 1 spinner |
| `frontend/lib/presentation/screens/insights_screen.dart` | Sostituzione 1 spinner |
| `frontend/lib/presentation/screens/dashboard_screen.dart` | Rimozione guard `isLoading` |

**Totale:** 5 file, ~50 righe modificate.

---

## Criteri di Successo

1. Nessun `CircularProgressIndicator` visibile durante il caricamento di liste/contenuti
2. Le schermate mostrano una struttura riconoscibile durante la decrittazione
3. L'animazione shimmer è fluida (60fps) su iPhone 12+
4. Dark mode: contrasto skeleton visibile ma non invasivo
5. Nessuna regressione sui button-spinner (azioni utente)
