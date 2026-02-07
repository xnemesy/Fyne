# Fyne Beta Release Guide (1.0.0-beta.1)

Questa guida dettaglia i passi necessari per distribuire la prima versione beta di Fyne su TestFlight (iOS) e Play Console (Android).

## 1. Firma della Build (Android)

Per generare un APK/AAB firmato per Android:

1. Genera un keystore (se non lo hai già):
   ```bash
   keytool -genkey -v -keystore ~/fyne-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fyne-key
   ```
2. Crea il file `android/key.properties` con i seguenti dati:
   ```properties
   storePassword=<tua_password>
   keyPassword=<tua_password>
   keyAlias=fyne-key
   storeFile=/Users/percorso/fyne-release-key.jks
   ```
3. Il file `android/app/build.gradle` è già configurato per leggere queste proprietà.

## 2. Hardening Checkpoint

Prima di caricare la build, conferma che:
- [x] Versioning in `pubspec.yaml` è `1.0.0-beta.1+1`.
- [x] Checksum validation è attiva nel `BackupService`.
- [x] Analytics & Crashlytics inizializzati in modalità privacy-first (no PII).
- [x] Autenticazione biometrica ha il fallback a PIN attivato.

## 3. Distribuzione iOS (TestFlight)

1. Apri `ios/Runner.xcworkspace` in Xcode.
2. Assicurati che il Bundle Identifier sia unico (es: `it.fyne.app`).
3. Seleziona **Product > Archive**.
4. Una volta completato, usa **Distribute App** e seleziona **App Store Connect**.
5. Gestisci i tester interni su [App Store Connect](https://appstoreconnect.apple.com).

## 4. Distribuzione Android (Internal Testing)

1. Genera il bundle:
   ```bash
   flutter build appbundle --release
   ```
2. Carica il file `.aab` (trovato in `build/app/outputs/bundle/release/`) su [Google Play Console](https://play.google.com/console).
3. Configura una traccia di "Internal Testing" e aggiungi le email dei tester.

## 5. Monitoraggio Beta

Accedi alle console per monitorare:
- **Firebase Crashlytics**: Controlla nuovi crash (saranno anonimi).
- **Firebase Analytics**: Verifica il tasso di successo degli export (`export_success`).

---
**Privacy Note**: Ricorda che Fyne non invia mai dati finanziari o PII alle console di monitoraggio. I log sono puramente tecnici e aggregati.
