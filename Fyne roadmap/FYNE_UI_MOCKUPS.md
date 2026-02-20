# 🎨 FYNE UI MOCKUPS - Budget & Scheduled Payments

## 📋 BUDGET MANAGER - Detailed Specifications

### Screen 1: Budget Overview (Dashboard)

```
╔═══════════════════════════════════════════════════════════════╗
║  ← Back                 💰 I Miei Budget           [+ Nuovo]  ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  📊 Riepilogo Mensile - Febbraio 2025                        ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Budget Totale: €2,800                               │   ║
║  │  Speso: €1,850 (66%)                                 │   ║
║  │  Rimanente: €950                                     │   ║
║  │  ████████████████░░░░░░░░░░                          │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  🟢 SOTTO BUDGET                                             ║
║  ┌─────────────────────────────────────────────────────┐     ║
║  │  🍕 Cibo & Ristoranti                    €450/€600  │     ║
║  │  ████████████░░░░░░░░░ 75%                          │     ║
║  │  Rimanenti: €150                                     │     ║
║  └─────────────────────────────────────────────────────┘     ║
║                                                               ║
║  ┌─────────────────────────────────────────────────────┐     ║
║  │  🚗 Trasporti                            €120/€200  │     ║
║  │  ██████░░░░░░░░░░░░░░░ 60%                          │     ║
║  │  Rimanenti: €80                                      │     ║
║  └─────────────────────────────────────────────────────┘     ║
║                                                               ║
║  🔴 OLTRE BUDGET                                             ║
║  ┌─────────────────────────────────────────────────────┐     ║
║  │  👔 Abbigliamento                        €380/€300  │     ║
║  │  ████████████████████░ 127%                          │     ║
║  │  ⚠️ Superato di €80                                  │     ║
║  └─────────────────────────────────────────────────────┘     ║
║                                                               ║
║  🟡 NON CATEGORIZZATO                                        ║
║  ┌─────────────────────────────────────────────────────┐     ║
║  │  ❓ Senza Budget                          €900       │     ║
║  │  12 transazioni non assegnate                        │     ║
║  │  [Assegna Budget]                                    │     ║
║  └─────────────────────────────────────────────────────┘     ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

**Widget Implementation:**
```dart
class BudgetOverviewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final currentMonth = DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('💰 I Miei Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => _showCreateBudgetDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMonthlySummaryCard(budgets, currentMonth),
            SizedBox(height: 24),
            _buildBudgetList(budgets, BudgetStatus.onTrack),
            SizedBox(height: 16),
            _buildBudgetList(budgets, BudgetStatus.overBudget),
            SizedBox(height: 16),
            _buildUncategorizedCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetCard(Budget budget, double spent) {
    final percentage = (spent / budget.amount) * 100;
    final remaining = budget.amount - spent;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      budget.emoji,
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(width: 8),
                    Text(
                      budget.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Text(
                  '€${spent.toStringAsFixed(0)}/€${budget.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: percentage > 100 ? FyneColors.rust : FyneColors.forest,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: FyneColors.paperDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 100 ? FyneColors.rust : FyneColors.forest,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              remaining > 0 
                ? 'Rimanenti: €${remaining.toStringAsFixed(0)}'
                : '⚠️ Superato di €${(-remaining).toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: remaining > 0 ? FyneColors.inkLight : FyneColors.rust,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Screen 2: Create/Edit Budget

```
╔═══════════════════════════════════════════════════════════════╗
║  ← Annulla                Nuovo Budget               [Salva]  ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  📝 DETTAGLI BASE                                            ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Nome Budget                                         │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │ Cibo & Ristoranti                           │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Emoji (opzionale)                                   │   ║
║  │  ┌──────┬──────┬──────┬──────┬──────┐               │   ║
║  │  │  🍕  │  🚗  │  💊  │  🎮  │  🏠  │               │   ║
║  │  └──────┴──────┴──────┴──────┴──────┘               │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Importo Mensile                                     │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │ € 600.00                                    │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  🎯 TIPO BUDGET                                              ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  ◉ Spesa Ricorrente                                  │   ║
║  │     Budget mensile che si resetta ogni 1° del mese   │   ║
║  │                                                       │   ║
║  │  ○ Obiettivo di Risparmio                            │   ║
║  │     Accumula fino a raggiungere l'obiettivo          │   ║
║  │                                                       │   ║
║  │  ○ Limite Annuale                                    │   ║
║  │     Budget che si resetta ogni anno                  │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  🏷️ CATEGORIE COLLEGATE                                      ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  [✓] Ristoranti                                      │   ║
║  │  [✓] Supermercati                                    │   ║
║  │  [✓] Fast Food                                       │   ║
║  │  [ ] Bar & Caffè                                     │   ║
║  │                                                       │   ║
║  │  + Aggiungi Categoria                                │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ⚙️ OPZIONI AVANZATE                                         ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  [✓] Abilita Rollover                                │   ║
║  │      Il budget non speso passa al mese successivo    │   ║
║  │                                                       │   ║
║  │  [ ] Notifiche al 80%                                │   ║
║  │      Ricevi un avviso quando raggiungi l'80%         │   ║
║  │                                                       │   ║
║  │  [✓] Mostra in Dashboard                             │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

**Data Model:**
```dart
@collection
class Budget {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  final String uuid;
  
  // Basic Info (encrypted)
  final String encryptedName;
  final String? emoji;
  final String encryptedAmount;
  final String currency;
  
  // Type & Period
  @enumerated
  final BudgetType type;
  
  @enumerated
  final BudgetPeriod period;
  
  // Linked Categories
  final List<String> categoryUuids;
  
  // Settings
  final bool rolloverEnabled;
  final bool notificationsEnabled;
  final double notificationThreshold; // 0.0 - 1.0 (es. 0.8 = 80%)
  final bool showInDashboard;
  
  // Dates
  final DateTime startDate;
  final DateTime? endDate; // null = ongoing
  
  // Metadata
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Transient (decrypted)
  @ignore
  String? decryptedName;
  
  @ignore
  double? decryptedAmount;
  
  Budget({
    required this.uuid,
    required this.encryptedName,
    this.emoji,
    required this.encryptedAmount,
    this.currency = 'EUR',
    this.type = BudgetType.recurring,
    this.period = BudgetPeriod.monthly,
    this.categoryUuids = const [],
    this.rolloverEnabled = false,
    this.notificationsEnabled = true,
    this.notificationThreshold = 0.8,
    this.showInDashboard = true,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Getters
  String? get name => decryptedName;
  double? get amount => decryptedAmount;
}

enum BudgetType {
  recurring,      // Spesa ricorrente (resetta ogni periodo)
  savings_goal,   // Obiettivo risparmio (accumula)
  annual_limit,   // Limite annuale
}

enum BudgetPeriod {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}
```

---

## 📅 SCHEDULED PAYMENTS - Detailed Specifications

### Screen 3: Scheduled Payments List

```
╔═══════════════════════════════════════════════════════════════╗
║  ← Back           📅 Pagamenti Programmati        [+ Nuovo]   ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  📌 PROSSIMI 7 GIORNI                                        ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  🏠 Affitto                                          │   ║
║  │  📆 Mensile • Ogni 1° del mese                       │   ║
║  │  💳 Conto Corrente UniCredit                         │   ║
║  │  💰 -€850.00                                         │   ║
║  │  ⏰ Prossimo: 01/02/2025 (tra 3 giorni)             │   ║
║  │                                                       │   ║
║  │  [Modifica]  [Paga Ora]                 [⋮ Altro]   │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  ⚡ Bolletta Luce                                    │   ║
║  │  📆 Bimestrale • Ogni 15                             │   ║
║  │  💳 Conto Corrente Intesa                            │   ║
║  │  💰 -€120.00                                         │   ║
║  │  ⏰ Prossimo: 15/02/2025 (tra 17 giorni)            │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  📅 QUESTO MESE (Febbraio)                                   ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  💪 Palestra McFit                                   │   ║
║  │  📆 Mensile • Ogni 10                                │   ║
║  │  💰 -€40.00                                          │   ║
║  │  ⏰ Prossimo: 10/02/2025                             │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  🎵 Spotify Premium                                  │   ║
║  │  📆 Mensile • Ogni 22                                │   ║
║  │  💰 -€9.99                                           │   ║
║  │  ⏰ Prossimo: 22/02/2025                             │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  💡 TIP: I pagamenti verranno creati automaticamente        ║
║      alla data prevista. Riceverai una notifica.             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

**Widget Implementation:**
```dart
class ScheduledPaymentsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledPayments = ref.watch(scheduledPaymentsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('📅 Pagamenti Programmati'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => _showCreateScheduledPayment(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('📌 PROSSIMI 7 GIORNI'),
          ..._buildUpcomingPayments(scheduledPayments, days: 7),
          
          SizedBox(height: 24),
          _buildSectionHeader('📅 QUESTO MESE'),
          ..._buildMonthlyPayments(scheduledPayments),
          
          SizedBox(height: 16),
          _buildTipCard(),
        ],
      ),
    );
  }
  
  Widget _buildScheduledPaymentCard(ScheduledPayment payment) {
    final daysUntilNext = payment.nextExecutionDate!.difference(DateTime.now()).inDays;
    
    return Card(
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    payment.emoji ?? '💳',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.description,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getRecurrenceText(payment),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-€${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FyneColors.rust,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: FyneColors.inkLight,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Prossimo: ${_formatDate(payment.nextExecutionDate!)} (tra $daysUntilNext giorni)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _editPayment(payment),
                    child: Text('Modifica'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _executeNow(payment),
                    child: Text('Paga Ora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FyneColors.forest,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _showPaymentMenu(payment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Screen 4: Create Scheduled Payment

```
╔═══════════════════════════════════════════════════════════════╗
║  ← Annulla         Nuovo Pagamento Programmato      [Salva]  ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  💳 DETTAGLI PAGAMENTO                                       ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Descrizione                                         │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │ Affitto Appartamento                        │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Importo                                             │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │ € 850.00                                    │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  Destinatario (opzionale)                            │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │ Mario Rossi                                 │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  📅 FREQUENZA                                                ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  ┌────────┬────────┬────────┬────────┐               │   ║
║  │  │ Giorn. │Settim. │ Mensile│ Annuale│               │   ║
║  │  └────────┴────────┴────────┴────────┘               │   ║
║  │           ⬤ Mensile selezionato                      │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  📆 Giorno del Mese                                  │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │         1  ▼                                │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  📅 Data Inizio                                      │   ║
║  │  ┌─────────────────────────────────────────────┐    │   ║
║  │  │ 01/02/2025                              📅  │    │   ║
║  │  └─────────────────────────────────────────────┘    │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  [ ] Imposta Data Fine                               │   ║
║  │      Lascia vuoto per pagamenti indefiniti           │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  🏦 CONTO DA ADDEBITARE                                      ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  💳 Conto Corrente UniCredit        €1,250.00        │   ║
║  │                                                 ✓     │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  🏷️ CATEGORIA                                                 ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  🏠 Casa & Affitto                                   │   ║
║  │                                                 ✓     │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
║  🔔 NOTIFICHE                                                ║
║  ┌───────────────────────────────────────────────────────┐   ║
║  │  [✓] Avvisami 3 giorni prima                         │   ║
║  │  [✓] Avvisami il giorno stesso                       │   ║
║  │  [ ] Avvisami dopo l'esecuzione                      │   ║
║  └───────────────────────────────────────────────────────┘   ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

**Data Model:**
```dart
@collection
class ScheduledPayment {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  final String uuid;
  
  // Payment Details (encrypted)
  final String encryptedAmount;
  final String encryptedDescription;
  final String? encryptedCounterParty;
  final String currency;
  final String? emoji;
  
  // Account & Category
  @Index()
  final String accountId;
  
  @Index()
  final String? categoryUuid;
  
  // Recurrence
  @enumerated
  final RecurrencePattern pattern;
  
  final int dayOfMonth;        // 1-31 (per monthly)
  final int? weekday;          // 1-7 (per weekly: 1=Monday)
  final int? monthOfYear;      // 1-12 (per yearly)
  
  // Dates
  final DateTime startDate;
  final DateTime? endDate;     // null = indefinito
  
  @Index()
  final DateTime? lastExecutionDate;
  
  @Index()
  final DateTime? nextExecutionDate;
  
  // Notifications
  final bool notifyBeforeExecution;
  final int? notifyDaysBefore;      // es. 3
  final bool notifyOnExecution;
  final bool notifyAfterExecution;
  
  // Status
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Transient
  @ignore
  double? decryptedAmount;
  
  @ignore
  String? decryptedDescription;
  
  @ignore
  String? decryptedCounterParty;
  
  ScheduledPayment({
    required this.uuid,
    required this.encryptedAmount,
    required this.encryptedDescription,
    this.encryptedCounterParty,
    this.currency = 'EUR',
    this.emoji,
    required this.accountId,
    this.categoryUuid,
    required this.pattern,
    this.dayOfMonth = 1,
    this.weekday,
    this.monthOfYear,
    required this.startDate,
    this.endDate,
    this.lastExecutionDate,
    this.nextExecutionDate,
    this.notifyBeforeExecution = true,
    this.notifyDaysBefore = 3,
    this.notifyOnExecution = false,
    this.notifyAfterExecution = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Getters
  double? get amount => decryptedAmount;
  String? get description => decryptedDescription;
  String? get counterParty => decryptedCounterParty;
}

enum RecurrencePattern {
  daily,
  weekly,
  biweekly,
  monthly,
  bimonthly,
  quarterly,
  yearly,
  custom,
}
```

---

## 🔔 NOTIFICATION SYSTEM

**Background Job Service:**
```dart
class ScheduledPaymentBackgroundService {
  static const String taskKey = 'check_scheduled_payments';
  
  /// Register background task (Android: WorkManager, iOS: Background Fetch)
  Future<void> registerBackgroundTask() async {
    await Workmanager().registerPeriodicTask(
      taskKey,
      taskKey,
      frequency: Duration(hours: 24), // Check once per day at midnight
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
  
  /// Callback eseguito in background
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == taskKey) {
        await _checkAndExecutePayments();
      }
      return Future.value(true);
    });
  }
  
  static Future<void> _checkAndExecutePayments() async {
    final isar = await Isar.open([/* schemas */]);
    final masterKey = await CryptoService().getOrGenerateMasterKey();
    
    final today = DateTime.now();
    
    // Trova pagamenti in scadenza oggi
    final duePayments = await isar.scheduledPayments
        .filter()
        .isActiveEqualTo(true)
        .nextExecutionDateBetween(
          today,
          today.add(Duration(hours: 23, minutes: 59)),
        )
        .findAll();
    
    for (final scheduled in duePayments) {
      // Decifra dati
      final decrypted = await _decryptScheduledPayment(scheduled, masterKey);
      
      // Crea transazione effettiva
      final transaction = TransactionModel(
        uuid: Uuid().v4(),
        accountId: scheduled.accountId,
        bookingDate: today,
        currency: scheduled.currency,
        encryptedAmount: scheduled.encryptedAmount,
        encryptedDescription: scheduled.encryptedDescription,
        encryptedCounterParty: scheduled.encryptedCounterParty,
        encryptedCategoryName: null,
        categoryUuid: scheduled.categoryUuid,
        createdAt: today,
      );
      
      await isar.writeTxn(() async {
        await isar.transactionModels.put(transaction);
      });
      
      // Aggiorna next execution date
      final nextDate = _calculateNextExecutionDate(scheduled);
      await isar.writeTxn(() async {
        scheduled.lastExecutionDate = today;
        scheduled.nextExecutionDate = nextDate;
        await isar.scheduledPayments.put(scheduled);
      });
      
      // Invia notifica
      await NotificationService().show(
        id: scheduled.hashCode,
        title: 'Pagamento Automatico Eseguito',
        body: '${decrypted.description}: -€${decrypted.amount.toStringAsFixed(2)}',
        payload: 'scheduled_payment:${scheduled.uuid}',
      );
      
      // Analytics
      AnalyticsService().logEvent('scheduled_payment_executed', {
        'pattern': scheduled.pattern.name,
      });
    }
    
    // Notifiche "3 giorni prima"
    final upcoming = await isar.scheduledPayments
        .filter()
        .isActiveEqualTo(true)
        .nextExecutionDateBetween(
          today.add(Duration(days: 3)),
          today.add(Duration(days: 3, hours: 23)),
        )
        .findAll();
    
    for (final scheduled in upcoming) {
      if (scheduled.notifyBeforeExecution && 
          scheduled.notifyDaysBefore == 3) {
        final decrypted = await _decryptScheduledPayment(scheduled, masterKey);
        
        await NotificationService().show(
          id: scheduled.hashCode + 1000,
          title: '⏰ Promemoria Pagamento',
          body: '${decrypted.description} (€${decrypted.amount}) tra 3 giorni',
          payload: 'scheduled_payment_reminder:${scheduled.uuid}',
        );
      }
    }
  }
  
  static DateTime _calculateNextExecutionDate(ScheduledPayment payment) {
    final lastExecution = payment.lastExecutionDate ?? payment.startDate;
    
    switch (payment.pattern) {
      case RecurrencePattern.daily:
        return lastExecution.add(Duration(days: 1));
        
      case RecurrencePattern.weekly:
        return lastExecution.add(Duration(days: 7));
        
      case RecurrencePattern.biweekly:
        return lastExecution.add(Duration(days: 14));
        
      case RecurrencePattern.monthly:
        var next = DateTime(
          lastExecution.year,
          lastExecution.month + 1,
          payment.dayOfMonth,
        );
        
        // Handle edge case: day doesn't exist in next month
        while (!_isValidDate(next)) {
          next = DateTime(next.year, next.month, next.day - 1);
        }
        
        return next;
        
      case RecurrencePattern.quarterly:
        return DateTime(
          lastExecution.year,
          lastExecution.month + 3,
          payment.dayOfMonth,
        );
        
      case RecurrencePattern.yearly:
        return DateTime(
          lastExecution.year + 1,
          payment.monthOfYear ?? lastExecution.month,
          payment.dayOfMonth,
        );
        
      default:
        return lastExecution.add(Duration(days: 30));
    }
  }
  
  static bool _isValidDate(DateTime date) {
    try {
      DateTime(date.year, date.month, date.day);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 📱 INTEGRATION WITH EXISTING CODE

### BudgetProvider (Riverpod)

```dart
@riverpod
class BudgetNotifier extends _$BudgetNotifier {
  @override
  Future<List<Budget>> build() async {
    return _loadBudgets();
  }
  
  Future<List<Budget>> _loadBudgets() async {
    final isar = await ref.read(isarProvider.future);
    final masterKey = ref.read(masterKeyProvider);
    
    if (masterKey == null) return [];
    
    final encrypted = await isar.budgets
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    
    // Decrypt in isolate
    final decrypted = await compute(
      _decryptBudgetList,
      _BudgetDecryptParams(budgets: encrypted, masterKeyBytes: await masterKey.extractBytes()),
    );
    
    return decrypted;
  }
  
  Future<void> createBudget({
    required String name,
    required double amount,
    required List<String> categoryUuids,
    String? emoji,
    BudgetType type = BudgetType.recurring,
    BudgetPeriod period = BudgetPeriod.monthly,
    bool rolloverEnabled = false,
  }) async {
    final isar = await ref.read(isarProvider.future);
    final masterKey = ref.read(masterKeyProvider);
    
    if (masterKey == null) throw Exception('Master key not initialized');
    
    final encrypted = await compute(
      _encryptBudget,
      _BudgetEncryptParams(
        uuid: Uuid().v4(),
        name: name,
        amount: amount,
        categoryUuids: categoryUuids,
        emoji: emoji,
        type: type,
        period: period,
        rolloverEnabled: rolloverEnabled,
        masterKeyBytes: await masterKey.extractBytes(),
      ),
    );
    
    await isar.writeTxn(() async {
      await isar.budgets.put(encrypted);
    });
    
    ref.invalidateSelf();
    AnalyticsService().logEvent('budget_created', {'type': type.name});
  }
  
  Future<double> getSpentAmount(Budget budget, DateTime month) async {
    final isar = await ref.read(isarProvider.future);
    
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final transactions = await isar.transactionModels
        .filter()
        .bookingDateBetween(startOfMonth, endOfMonth)
        .categoryUuidIsIn(budget.categoryUuids)
        .findAll();
    
    // Decrypt amounts
    final masterKey = ref.read(masterKeyProvider);
    if (masterKey == null) return 0.0;
    
    final repo = TransactionRepository(isar, masterKey);
    double totalSpent = 0.0;
    
    for (final tx in transactions) {
      final decrypted = await repo.decryptSingle(tx);
      if (decrypted.amount != null && decrypted.amount! < 0) {
        totalSpent += decrypted.amount!.abs();
      }
    }
    
    return totalSpent;
  }
}
```

---

## ✅ CHECKLIST IMPLEMENTAZIONE

### Budget System
- [ ] Creare `Budget` model in Isar
- [ ] Implementare `BudgetRepository` con encryption/decryption
- [ ] Creare `BudgetProvider` (Riverpod)
- [ ] UI: Budget Overview Screen
- [ ] UI: Create/Edit Budget Screen
- [ ] UI: Budget Detail Screen (con lista transazioni)
- [ ] Logic: Calcolo spent amount per categoria
- [ ] Logic: Rollover budget (spesa non utilizzata)
- [ ] Notifications: Alert al 80% e 100%
- [ ] Dashboard: Widget riepilogo budget

### Scheduled Payments
- [ ] Creare `ScheduledPayment` model in Isar
- [ ] Implementare `ScheduledPaymentRepository`
- [ ] Creare `ScheduledPaymentProvider`
- [ ] UI: Scheduled Payments List Screen
- [ ] UI: Create/Edit Scheduled Payment Screen
- [ ] Background Job: Setup WorkManager/Background Fetch
- [ ] Background Job: Check & execute payments
- [ ] Background Job: Calculate next execution date
- [ ] Notifications: 3 giorni prima, giorno stesso, post-execution
- [ ] Dashboard: Widget "Prossimi Pagamenti"

### Integration
- [ ] Aggiornare Dashboard con Budget & Scheduled widgets
- [ ] Creare sezione Settings per abilitare/disabilitare auto-execution
- [ ] Testing: Edge cases (28/29/30/31 febbraio, leap years)
- [ ] Testing: Performance con 100+ scheduled payments
- [ ] Analytics: Track budget creation, overspending events

---

**Stima Sviluppo**: 6-8 settimane per developer singolo (full-time)
