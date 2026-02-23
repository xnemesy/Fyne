import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ThemeNotifier — Fyne impone esclusivamente il Dark Theme.
/// Il `_loadTheme()` asincrono precedente causava un crash GlobalKey
/// perché emetteva `ThemeMode.light` dopo la build, forzando
/// la ri-creazione di tutto l'albero widget (InkFeatures, NotificationListener).
/// Soluzione: `build()` ritorna ThemeMode.dark in modo sincrono e definitivo.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // Dark forzato, sincrono, nessun async

  /// No-op: il toggle Light/System è disabilitato per spec Fyne.
  /// Mantenuto per API compatibility (es. tile Settings che mostra lo stato).
  Future<void> setThemeMode(ThemeMode mode) async {
    // Solo dark è accettato — fare override sarebbe un UX bug
    if (mode == ThemeMode.dark) state = ThemeMode.dark;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
