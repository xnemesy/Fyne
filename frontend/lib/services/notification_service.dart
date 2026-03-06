import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
    tz.initializeTimeZones();
  }

  Future<void> scheduleDailyBudgetNotification(double amount) async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Buongiorno da Fyne 🌿',
      'Per oggi il tuo budget disponibile è di ${amount.toStringAsFixed(2)} €. Buona giornata!',
      _nextInstanceOfMorning(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_budget_channel',
          'Daily Budget',
          channelDescription: 'Daily budget allowance notification',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfMorning() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 30); // 8:30 AM
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // ── Spese programmate ──────────────────────────────────────────────────────

  /// Schedula un reminder per la prossima occorrenza di una spesa programmata.
  /// [description] deve essere già decifrato — mai testo cifrato nella notifica.
  Future<void> scheduleTransactionReminder({
    required String id,
    required String description,
    required double amount,
    required DateTime nextOccurrence,
  }) async {
    // Salta date già passate
    if (nextOccurrence.isBefore(DateTime.now())) return;

    // UUID → int positivo in range sicuro per il plugin
    final notifId = id.hashCode.abs() % 2147483647;

    final scheduledDate = tz.TZDateTime.from(nextOccurrence, tz.local);

    await _notificationsPlugin.zonedSchedule(
      notifId,
      'Pagamento in scadenza',
      '$description • ${amount.abs().toStringAsFixed(2)} €',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_tx_channel',
          'Spese Programmate',
          channelDescription: 'Promemoria pagamenti programmati',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancella il reminder per la spesa con l'ID specificato.
  Future<void> cancelTransactionReminder(String id) async {
    final notifId = id.hashCode.abs() % 2147483647;
    await _notificationsPlugin.cancel(notifId);
  }

  /// Rischedula i reminder per tutte le spese programmate attive.
  /// Cancella prima i reminder precedenti (per ID noti) e ne crea di nuovi.
  /// I dati passati devono essere già decifrati.
  Future<void> rescheduleTransactionReminders({
    required List<String> previousIds,
    required List<Map<String, dynamic>> transactions,
  }) async {
    // Cancella i reminder delle transazioni precedenti
    for (final oldId in previousIds) {
      await cancelTransactionReminder(oldId);
    }

    // Schedula i reminder aggiornati
    for (final tx in transactions) {
      await scheduleTransactionReminder(
        id:             tx['id'] as String,
        description:    tx['description'] as String,
        amount:         tx['amount'] as double,
        nextOccurrence: tx['nextOccurrence'] as DateTime,
      );
    }
  }
}
