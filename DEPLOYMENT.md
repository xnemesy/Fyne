# Fyne Deployment & Marketing Guide

## 📦 Bundling & Distribution

### Android (.aab)
To generate the Android App Bundle for Play Store:
```bash
cd frontend
flutter build appbundle --release
```
**Prerequisites**: 
- `key.properties` file in `android/` with your signing key path and passwords.
- Upload to Play Console for Internal Testing or Production.

### iOS (.ipa)
To generate the IPA for TestFlight:
```bash
cd frontend
flutter build ipa --export-method app-store
```
**Prerequisites**:
- Xcode signed with a valid Apple Developer Distribution Certificate.
- Provisioning Profile with the bundle ID `app.fyne.ios`.
- Upload via Transporter or `xcrun altool`.

## 📣 Marketing & TestFlight Focus
**Tagline**: *Fyne: Private Deterministic Aggregation*

### Description for TestFlight
Fyne is the first multi-platform banking aggregator built on a **Zero-Knowledge** architecture. 
Unlike traditional apps (MoneyWiz, Mint, etc.), Fyne never sees your transaction data. 

**Key Features to Test**:
- **Privacy Deterministic Aggregation**: Connect your bank via GoCardless. Your device categorizes and encrypts everything BEFORE it reaches our servers.
- **Client-Side Learning**: Change a category and watch the device learn your habits locally.
- **Master Recovery Key**: Your 24-word mnemonic is the ONLY way to access your data. We can't reset your password because we don't have your keys.

### Privacy Focus
Our **Privacy Info Manifest** explicitly declares that financial data is NOT linked to your identity. We aggregate anonymous UUIDs to provide powerful budgeting without spying on your lifestyle.
