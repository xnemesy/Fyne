import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyne_frontend/providers/privacy_provider.dart';

void main() {
  testWidgets('PrivacyNotifier state changes with lifecycle', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final privacyState = container.read(privacyProvider);
      expect(privacyState.isAppInBackground, false);

      final notifier = container.read(privacyProvider.notifier);

      notifier.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump();
      
      expect(container.read(privacyProvider).isAppInBackground, true);
      expect(container.read(privacyProvider).isBlurred, true);
    });
  });
}
