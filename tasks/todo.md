# Fyne — Task Tracker Agenti 1–4
_Aggiornato da: Agente QA — 2026-03-06_

---

## Legenda
| Simbolo | Significato |
|---------|-------------|
| ✅ | Completato e verificato |
| ⚠️ | Completato con regressione / richiede fix |
| ❌ | Non completato |
| 🔴 | Bloccante per beta |

---

## Agente 1 — Dashboard Refactoring

| # | Task | Stato | Note |
|---|------|--------|------|
| 1.1 | `AccountCarousel` → `dashboard/account_carousel.dart` (PageView snapping) | ✅ | File presente e funzionante |
| 1.2 | `BalanceChart` → `dashboard/balance_chart.dart` (fl_chart LineChart) | ✅ | Completato in scope (bug sintassi tracciato in Regressioni) |
| 1.3 | `dashboard_screen.dart` → `CustomScrollView + Slivers` | ✅ | Verificato |
| 1.4 | `_buildFingerprint` referenziato ma non definito in `dashboard_screen.dart:307` | ✅ | Completato in scope (bug pre-esistente tracciato in Regressioni) |

---

## Agente 2 — Skeleton Loading

| # | Task | Stato | Note |
|---|------|--------|------|
| 2.1 | `FyneAccountShimmer`, `FyneInsightsShimmer` aggiunti a `fyne_shimmer.dart` | ✅ | |
| 2.2 | `CircularProgressIndicator` rimossi da `transactions_screen` | ✅ | |
| 2.3 | `CircularProgressIndicator` rimossi da `wallet_screen` | ✅ | |
| 2.4 | `CircularProgressIndicator` rimossi da `insights_screen` | ✅ | |
| 2.5 | `CircularProgressIndicator` rimossi da `dashboard_screen` | ✅ | |
| 2.6 | `FyneBudgetShimmer` aggiunto a `fyne_shimmer.dart` | ✅ | |
| 2.7 | `FyneScheduledShimmer` aggiunto a `fyne_shimmer.dart` | ✅ | |
| 2.8 | `budgets_screen.dart` spinner → shimmer | ✅ | |
| 2.9 | `scheduled_screen.dart` spinner → shimmer | ✅ | |

---

## Agente 3 — Async-Gap Safety

| # | Task | Stato | Note |
|---|------|--------|------|
| 3.1 | `account_overview_provider`: `ref.read/watch` dopo `await` eliminati | ✅ | |
| 3.2 | `account_provider`: fix async-gap | ✅ | |
| 3.3 | `scheduled_provider`: fix async-gap | ✅ | |
| 3.4 | `cloud_backups_provider`: fix async-gap | ✅ | |
| 3.5 | `sync_provider`: fix async-gap | ✅ | |
| 3.6 | `transaction_form_provider`: fix async-gap | ✅ | |
| 3.7 | `categorization_provider._loadRules`: `watch` → `read` | ✅ | |
| 3.8 | `key_rotation_service`: rimossi `_ref` e `_crypto` inutilizzati | ✅ | |
| 3.9 | `flutter analyze` 0 nuovi warning/errori al termine sessione 3 | ✅ | Valido a fine sessione 3; nuovi errori introdotti in sessione 4 |

---

## Agente 4 — Debito Tecnico (3A/3B/3C)

| # | Task | Stato | Note |
|---|------|--------|------|
| 4.1 | `transaction_repository.dart`: `getDecryptedTransactionsInRange` | ✅ | |
| 4.2 | `transaction_repository.dart`: `getSpentByCategoriesInRange` | ✅ | |
| 4.3 | `budget_provider.dart`: `monthlyCategorySpentProvider` | ✅ | |
| 4.4 | `budget_provider.dart`: `budgetSummaryProvider` usa nuovo provider | ✅ | |
| 4.5 | `insights_provider.dart`: `_recalculate` usa `getDecryptedTransactionsInRange` | ✅ | |
| 4.6 | `insights_provider.dart`: `_filterByPeriod` → `_periodRange` | ✅ | |
| 4.7 | `notification_service.dart`: `scheduleTransactionReminder` | ✅ | |
| 4.8 | `notification_service.dart`: `cancelTransactionReminder` | ✅ | |
| 4.9 | `notification_service.dart`: `rescheduleTransactionReminders` | ✅ | |
| 4.10 | `scheduled_provider.dart`: notifiche schedulate dopo fetch | ✅ | |
| 4.11 | `scheduled_provider.dart`: notifiche cancellate su delete + rollback | ✅ | |
| 4.12 | `budgets_screen.dart`, `scheduled_screen.dart`: `Colors.white` → `colorScheme.surface` | ✅ | |

---

## ✅ Regressioni Risolte (Sessione 6)

Tutte le regressioni sono state corrette. **`flutter analyze` → 0 errori.**

| # | File | Errore | Stato |
|---|------|--------|-------|
| R1 | `budget_card.dart` | `const FyneColors.amber` → sintassi costruttore inesistente | ✅ |
| R2 | `compact_cash_flow_chart.dart` | `const FyneColors.forest` → idem | ✅ |
| R3 | `daily_allowance_card.dart` | `const FyneColors.forest` → idem | ✅ |
| R4 | `edit_account_sheet.dart` | `const FyneColors.danger` → idem | ✅ |
| R5 | `edit_budget_sheet.dart` | `const FyneColors.danger` → idem | ✅ |
| R6 | `insights/net_worth_chart.dart` | `const FyneColors.forest` → idem | ✅ |
| R7 | `category_picker_sheet.dart` | `Category(id, name)` mancano `color` e `icon` required | ✅ |
| R8 | `dashboard/balance_chart.dart` | `tooltipRoundedRadius` non esiste in `LineTouchTooltipData` | ✅ |
| R9 | `dashboard_screen.dart` | `_buildFingerprint` undefined | ✅ |

---

## Warnings (Non-Bloccanti)

| File | Riga | Warning | Pre-esistente? |
|------|------|---------|----------------|
| `scheduled_provider.dart:89` | `_mockScheduled` unused element | Probabilmente sì |
| `transaction_provider.dart:116` | `invalid_use_of_internal_member` (copyWithPrevious) | Probabilmente sì |
| `vault_integrity_service.dart:20` | `count` unused local variable | Probabilmente sì |
| `fcm_service.dart:15,23,90,91` | 4 variabili locali inutilizzate | Probabilmente sì |
| `bank_selection_screen.dart:7` | Unused import `fyne_theme.dart` | Probabilmente sì |
| `categorization_rules_screen.dart:7` | Unused import `fyne_theme.dart` | Nuovo (fyne_theme.dart modificato) |

---

## KPI Beta Readiness

| KPI | Target | Attuale | Pass? |
|-----|--------|---------|-------|
| `flutter analyze` errori | 0 | **0** | ✅ |
| `flutter analyze` warning (non pre-approvati) | 0 | 1–2 | ⚠️ |
| `backup_service.importEncryptedBackup` checksum | ✅ attivo | ✅ attivo | ✅ |
| `backup_service.importEncryptedBackup` encryption scope | ✅ attivo | ✅ attivo | ✅ |
| `pubspec.yaml` versione beta | `1.0.0-beta.1+1` | `1.0.0-beta.1+1` | ✅ |

