# Fyne: Zero-Knowledge Financial Intelligence 🛡️🏛️

Fyne is a premium personal finance application designed with a **Privacy-First, Zero-Knowledge architecture**. It provides a high-end editorial user experience for managing assets, budgets, and transactions while ensuring that financial data remains strictly under the user's control.

---

## 🤖 Overview for External Agents / Developers

Fyne is built on the principle that **financial data should never be visible to the service provider**. All sensitive information is encrypted on the client device before reaching the cloud.

### 🏛️ Core Architecture
- **Frontend**: Flutter (Cross-platform iOS/Android).
- **Backend**: Node.js/Express service deployed on **Google Cloud Run** (`europe-west8`).
- **Auth**: **Firebase Authentication** (Handles user identity only; strictly decoupled from financial data).
- **Security Logic**: Client-side encryption using a hybrid model:
  - **AES-256 (PBKDF2)**: Used for manually entered accounts and transactions. Derived from a local "Master Key".
  - **RSA-2048**: Used for banking synchronization. Public keys are stored on the server to allow the backend to encrypt bank feeds, which only the client can decrypt with the local private key.

### 🔐 Security & Privacy Implementation
- **Zero-Knowledge Sync**: The server stores only encrypted blobs. Even a full server breach would reveal no transaction details, balance amounts, or account names.
- **Local Intelligence**: Transaction categorization (ML-based) runs locally on-device using **TFLite**. No clear-text transaction descriptions are ever sent to a cloud logic engine.
- **Biometric Protection**: Includes a `PrivacyBlurOverlay` to protect sensitive data from prying eyes/screenshots by applying a cinematic blur when the app is in the background or locked.

---

## 🚀 Key Features & UI/UX

- **Editorial UI**: A "Neo-Minimalist" aesthetic leveraging `Lora` for serif elegance and `Inter` for technical precision.
- **Dynamic Net Worth**: Real-time asset tracking with historical charts calculated locally from encrypted transaction logs.
- **Budget Intelligence**: Daily allowance calculations and burn-rate analysis to help users reach their savings goals.
- **MoneyWiz Dynamics**: Atomic balance updates. Manual expenses are subtracted locally, re-encrypted, and synced to ensure immediate consistency of the account balance.

---

## 🛠️ Project Structure

- `/frontend`: Flutter app. State managed via **Riverpod**.
- `/backend`: Banking Abstraction Layer. Orchestrates encrypted bank feeds and data indexing.
- `/infrastructure`: Terraform/Bash scripts for GCP deployment.

---

## 📝 Latest Stability Updates (v1.2.0)
- ✅ **Optimized Startup**: ML Model loading deferred to after the first frame to ensure zero splash-screen lag.
- ✅ **Multi-Auth**: Support for Email/Password and Anonymous login with automatic cryptographic vault initialization.
- ✅ **Interactive UI**: Gesture-based management (swipe-to-delete) for accounts, budgets, and transactions.
- ✅ **Localization**: Support for European decimal formats (comma/dot) in all financial inputs.

---

## 🏗️ Getting Started

```bash
# Clone and enter the project
git clone [repo-url]
cd Fyne/frontend

# Install dependencies and build
flutter pub get
flutter build ios --debug --no-codesign --simulator
```

**Developer Note**: Always use the `CryptoService` wrapper for API interactions. Never pass clear-text `description` or `amount` fields to the `ApiService`.
