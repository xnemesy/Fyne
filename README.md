# Fyne - Zero-Knowledge Financial Intelligence

Fyne is a multi-platform banking aggregator (iOS, Android, macOS) built with a **Zero-Knowledge** architecture. Your financial data is encrypted on your device and never seen by our servers in clear text.

## 🚀 Features
- **Client-Side Encryption**: AES-256 and PBKDF2 safeguard your transactions.
- **On-Device Categorization**: Intelligent rule-based and ML categorization.
- **Biometric Export**: FaceID/TouchID protected CSV exports.
- **Private Budgeting**: Aggregate spending without revealing lifestyle habits.

## 🛠️ Backend Setup (Node.js + PostgreSQL)
1. **Cloud SQL**: Set up a PostgreSQL instance.
2. **Environment Variables**: Create a `.env` file in `backend/` based on `.env.example`.
3. **GoCardless API**:
   - Register at [GoCardless (Nordigen)](https://gocardless.com/bank-account-data/).
   - Get your `SECRET_ID` and `SECRET_KEY`.
   - Add them to `.env`.
4. **Deploy**:
   ```bash
   gcloud run deploy banking-abstraction-layer --source ./backend
   ```

## 📱 Frontend Setup (Flutter)
1. **Prerequisites**: Flutter SDK installed and in PATH.
2. **Install Dependencies**:
   ```bash
   cd frontend
   flutter pub get
   ```
3. **Run**:
   ```bash
   flutter run
   ```

## 🔐 Zero-Knowledge Design
- **Deterministic Aggregation**: Categories use UUID v5 namespaces to ensure cross-device consistency without leaking category names to the server.
- **Encrypted Balances**: Even account balances are stored as encrypted blobs.

## 📦 Deployment (Fastlane)
Refer to `DEPLOYMENT.md` for manual instructions or use the `fastlane` lane:
```bash
# iOS
bundle exec fastlane ios beta
# Android
bundle exec fastlane android beta
```

## ⚖️ Privacy
Our **Privacy Info Manifest** (iOS) confirms that no financial data is linked to user identity.
