import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'daily_budget_provider.dart';
import '../services/notification_service.dart';

final notificationSchedulerProvider = Provider<void>((ref) {
  final dailyInfo = ref.watch(dailyBudgetProvider);
  
  // We only schedule if we have a valid allowance
  if (dailyInfo.dailyAllowance > 0) {
    NotificationService().scheduleDailyBudgetNotification(dailyInfo.dailyAllowance);
  }
});
