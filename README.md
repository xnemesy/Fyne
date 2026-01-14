# Fyne - Zero-Knowledge Financial Intelligence

Fyne is a premium financial intelligence application built with a **Zero-Knowledge** architecture. It prioritizes absolute privacy, sophisticated aesthetics, and real-time insights without ever exposing your financial life to the server in clear text.

## 🚀 Features & Status (v1.0.0-stable)
- **Neo-Minimalist Editorial UI**: A high-end aesthetic inspired by editorial design. Palette: Paper White (`#FBFBF9`), Deep Sage Green (`#4A6741`), Charcoal Grey (`#1A1A1A`).
- **Zero-Knowledge Architecture**: Financial data is encrypted locally using AES-256 (PBKDF2) before syncing. No clear-text transaction descriptions or amounts are stored on the server.
- **Local Smart Categorization**: An on-device engine (Rule-based + ML) maps transactions to categories using deterministic UUIDs (v5) for cross-device consistency.
- **iOS TestFlight Ready**: Successfully archived and deployed with Bundle ID `app.fyne.ios`.
- **Backend v11.0.0**: High-performance Node.js/Express layer on Google Cloud Run with automated PostgreSQL schema migrations.

## 🛠️ Project Structure
- `/frontend`: Flutter application. Uses Isar for local encrypted storage and Riverpod for state management.
- `/backend`: Node.js server. Handles encrypted transaction syncing and GoCardless (Nordigen) bank integration.
- `/docs`: Contains ASO metadata, deployment logs, and UI preview mocks.

## 📱 Getting Started (Frontend)
1. **Infrastructure**:
   ```bash
   cd frontend
   flutter pub get
   # Code generation for Isar and Riverpod
   dart run build_runner build --delete-conflicting-outputs
   ```
2. **iOS Build**:
   - Open `ios/Runner.xcworkspace` in Xcode.
   - Deployment target: iOS 13.0+.
   - Bundle ID: `app.fyne.ios`.
   - Ensure `Allow Non-modular Includes in Framework Modules` is set to **YES** in Build Settings.

## 🛠️ Backend Setup
1. **Deploy to Cloud Run**:
   ```bash
   gcloud run deploy banking-abstraction-layer --source ./backend
   ```
2. **DB Schema**: PostgreSQL tables for `accounts`, `transactions`, and `budgets` are initialized automatically on startup.

## 🤖 Handover Info (For External Agents)
If you are taking over this task, please note the following critical implementation details:
- **Encryption**: Always use `CryptoService` for any financial field. Never send raw descriptions to the `/api/transactions` endpoints.
- **Categorization**: Use the deterministic UUID v5 generator in `CategorizationService` to ensure the backend can aggregate data without knowing the category names.
- **iOS Issues**: If you encounter "non-modular header" errors in CocoaPods, verify the `post_install` hook in the `Podfile` matches the current configuration (allows non-modular includes).
- **TFLite**: A placeholder `category_model.tflite` exists in `assets/models/` to satisfy build dependencies until the production model is trained.

---
**Privacy Policy**: Fyne does NOT link financial data to user identity. All "Intelligence" features are processed locally on the user's silicon.
