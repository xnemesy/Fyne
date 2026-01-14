import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'transaction_provider.dart';
import 'account_provider.dart';
import 'budget_provider.dart';

final syncProvider = Provider<void>((ref) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data['type'] == 'SYNC_READY') {
      print("🔔 SYNC_READY received! Refreshing providers...");
      ref.invalidate(transactionsProvider);
      ref.read(accountsProvider.notifier).refresh();
      ref.read(budgetsProvider.notifier).refresh();
    }
  });
});
