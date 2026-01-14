import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget_provider.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final budgetOverrunHandlerProvider = Provider<void>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);

  budgetsAsync.whenData((budgets) {
    for (var budget in budgets) {
      if (budget.limitAmount > 0) {
        final usage = budget.currentSpent / budget.limitAmount;
        if (usage >= 0.9) {
          final percentage = (usage * 100).toStringAsFixed(0);
          final categoryName = budget.decryptedCategoryName ?? "Categoria";
          
          NotificationService().scheduleCustomNotification(
            id: budget.id.hashCode,
            title: '⚠️ Budget quasi esaurito',
            body: 'Hai utilizzato il $percentage% del budget per $categoryName.',
          );
        }
      }
    }
  });
});

extension on NotificationService {
  Future<void> scheduleCustomNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // This uses the existing notification plugin instance
    await FlutterLocalNotificationsPlugin().show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Avvisi Budget',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
