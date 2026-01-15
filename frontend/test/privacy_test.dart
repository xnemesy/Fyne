import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyne_frontend/providers/privacy_provider.dart';

void main() {
  testWidgets('PrivacyNotifier state changes with lifecycle', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final privacyState = container.read(privacyProvider);
    expect(privacyState.isAppInBackground, false);

    // Access the notifier through the container
    final notifier = container.read(privacyProvider.notifier);

    // Simulate lifecycle change
    notifier.didChangeAppLifecycleState(AppLifecycleState.inactive);
    
    expect(container.read(privacyProvider).isAppInBackground, true);
    expect(container.read(privacyProvider).isBlurred, true);
  });
}
