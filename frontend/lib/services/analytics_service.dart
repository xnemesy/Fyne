import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Servizio di Analytics & Crash reporting Privacy-First.
/// Gestisce l'invio di eventi e log errori senza mai includere PII o dati finanziari.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Inizializza Crashlytics.
  Future<void> init() async {
    if (kDebugMode) {
      // Disabilita Crashlytics in debug per evitare rumore
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      // Assicura che non ci siano identificativi utente
      await FirebaseCrashlytics.instance.setUserIdentifier("");
    }
  }

  /// Traccia un evento anonimo.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Filtriamo i parametri per sicurezza extra
    final safeParams = parameters?.map((key, value) {
      // Se il valore sembra un dato sensibile (es. un importo o una descrizione lunga), lo oscuriamo o lo scartiamo
      if (key.contains('amount') || key.contains('description') || key.contains('name')) {
        return MapEntry(key, 'REDACTED');
      }
      return MapEntry(key, value);
    });

    await _analytics.logEvent(name: name, parameters: safeParams);
    debugPrint('[Analytics] Evento tracciato: $name');
  }

  /// Logga un errore non fatale su Crashlytics.
  Future<void> logError(dynamic exception, StackTrace? stack, {String? reason}) async {
    if (kDebugMode) {
      print('[Crashlytics] Errore simulato: $exception');
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      printDetails: false, // Evita print in log di sistema in chiaro
    );
  }

  // Pre-defined events for Beta Hardening
  Future<void> logExportSuccess() => logEvent('export_success');
  Future<void> logExportFail(String reason) => logEvent('export_fail', parameters: {'reason': reason});
  Future<void> logImportSuccess() => logEvent('import_success');
  Future<void> logImportFail(String reason) => logEvent('import_fail', parameters: {'reason': reason});
  Future<void> logBiometricFail() => logEvent('biometric_fail');
}
