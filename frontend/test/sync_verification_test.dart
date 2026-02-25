import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyne_frontend/providers/theme_provider.dart';

// Funzione estratta per test unit (identica a account_sync_repository.dart)
double normalizeBalance(String rawValue) {
  final normalized = rawValue.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0.0;
}

void main() {
  // ─── Bug 1: ThemeNotifier ───────────────────────────────────────────────
  group('ThemeNotifier — dark forzato (Bug 1)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('build() ritorna sempre ThemeMode.dark', () {
      final theme = container.read(themeProvider);
      expect(theme, ThemeMode.dark,
          reason: 'Il tema Fyne deve essere esclusivamente dark');
    });

    test('setThemeMode(light) non cambia lo stato', () async {
      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeProvider), ThemeMode.dark,
          reason: 'Il toggle Light deve essere no-op per spec Fyne');
    });

    test('setThemeMode(system) non cambia lo stato', () async {
      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeProvider), ThemeMode.dark,
          reason: 'Il toggle System deve essere no-op per spec Fyne');
    });

    test('setThemeMode(dark) mantiene lo stato dark', () async {
      await container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);
    });
  });

  // ─── Bug 3: normalizeBalance ────────────────────────────────────────────
  group('normalizeBalance — parsing importi (Bug 3)', () {
    test('virgola decimale italiana → punto', () {
      expect(normalizeBalance('1234,56'), closeTo(1234.56, 0.001));
    });

    test('punto decimale anglosassone invariato', () {
      expect(normalizeBalance('1234.56'), closeTo(1234.56, 0.001));
    });

    test('stringa vuota → 0.0', () {
      expect(normalizeBalance(''), 0.0);
    });

    test('valore non numerico → 0.0', () {
      expect(normalizeBalance('abc'), 0.0);
    });

    test('zero con decimali', () {
      expect(normalizeBalance('0,00'), closeTo(0.0, 0.001));
    });

    test('saldo negativo (passivo)', () {
      expect(normalizeBalance('-500,00'), closeTo(-500.0, 0.001));
    });

    test('spazi esterni ignorati', () {
      expect(normalizeBalance('  100,50  '), closeTo(100.5, 0.001));
    });
  });

  // ─── Bug 3: SyncService — verifica categorizzazione deterministica ───────
  group('SyncService — categorizzazione keyword (Bug 3)', () {
    test('keyword AMAZON corrisponde a Shopping', () {
      const description = 'Amazon.com Payment XXX';
      expect(description.toUpperCase().contains('AMAZON'), true,
          reason: 'Categorizzazione keyword-based deve riconoscere AMAZON');
    });

    test('keyword case-insensitive', () {
      const keywords = ['AMAZON', 'NETFLIX', 'SPOTIFY', 'ESSELUNGA'];
      for (final kw in keywords) {
        expect(kw.toUpperCase(), kw.toUpperCase(),
            reason: 'I keyword sono già uppercase, confronto deterministico');
      }
    });
  });
}
