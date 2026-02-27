import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeNotifier con persistenza via SharedPreferences.
///
/// **Soluzione anti-crash GlobalKey:**
/// Il vecchio crash era causato da `_loadTheme()` asincrono che emetteva
/// `ThemeMode.light` DOPO la prima build, forzando la ri-creazione dell'intero
/// albero widget (InkFeatures, NotificationListener → "Multiple widgets used
/// the same GlobalKey").
///
/// Fix: il tema viene caricato in `main()` PRIMA di `runApp()` come
/// ProviderScope override → `build()` ritorna il valore corretto al frame 0,
/// nessun cambio di tema post-build.
class ThemeNotifier extends Notifier<ThemeMode> {
  final ThemeMode _initialMode;

  ThemeNotifier(this._initialMode);

  @override
  ThemeMode build() => _initialMode; // Sincronizzato prima di runApp()

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode; // Aggiornamento sincrono — nessun crash GlobalKey
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fyne_theme', mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  () => ThemeNotifier(ThemeMode.dark), // Default — overridato da ProviderScope in main()
);
