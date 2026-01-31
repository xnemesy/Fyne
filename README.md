# Fyne: Zero-Knowledge Financial Intelligence 🛡️🏛️

**Fyne** is a premium personal finance application built on a radical premise: **Total Privacy** meets **Digital Luxury**. It is designed for users who demand control without compromise, offering a high-end editorial experience for asset management, budgeting, and financial planning.

The architecture is **Zero-Knowledge**: the backend is "blind," storing only encrypted blobs. All intelligence, categorization, and analysis happen locally on the device.

---

## 🧭 Product Philosophy: Orientation over Information

Fyne rejects the dashboard anxiety of traditional finance apps. We do not just show data; we provide **orientation**.

### 1. The Home Compass (State, Not Stats)
The `Home` screen answers a single question: *"Am I in balance?"*
- **State Block**: A computed textual status (e.g., *Stable Balance*, *Settling Phase*).
- **The Compass**: The **Average Daily Space** metric. It is a reference point, not a rigid limit.
- **Context**: Minimal insights (e.g., *"Includes 3 future expenses"*).

### 2. The Rule of Silence
Fyne only speaks when necessary.
- **No Engagement Spam**: No gamification badges, no "daily streak" notifications.
- **Micro-Awareness**: Instead of monthly reports, Fyne provides real-time feedback during transaction entry (e.g., *"This affects 15% of your daily space"*).

### 3. Neo-Minimalism
- **Typography**: `Lora` (Serif) for human numbers/headers, `Inter` (Sans) for technical data.
- **Hierarchy**: The **Status** is the protagonist; raw data is secondary.
- **Color**: Used semantically (Olive for Balance, Amber for Attention, Terra Cotta for Critical), never decoratively.

---

## 🏗️ System Architecture

### 🔧 Tech Stack
- **Framework**: Flutter (Dart 3.x)
- **State Management**: **Riverpod 2.0** (with `riverpod_generator` & `freezed` patterns).
- **Local Database**: **Isar** (NoSQL, Typed, Async).
- **Encryption**: `AES-256-GCM` (Local), `RSA-2048` (Sync).
- **ML Engine**: `tflite_flutter` (Local inference for categorization).

### 🔐 Security & Privacy (Zero-Knowledge)
This is the core invariant of the system.
1.  **Local Encryption**: All sensitive fields (`amount`, `description`, `balance`) are encrypted with a device-generated **Master Key** (stored in Secure Storage) *before* touching the disk or network.
2.  **Blind Backend**: The server receives only `encryptedBlob`. It cannot see user data.
3.  **Hybrid Sync**:
    -   Client generates RSA Keypair.
    -   Public Key is shared with the backend.
    -   Banking providers (GoCardless/Tink) encrypt data via Backend using the Public Key.
    -   Only the device (Private Key) can decrypt the bank feed.

---

## 🧠 Key Logic Modules

### 1. The Home State Engine (`home_state_provider.dart`)
Determines the user's financial "weather" based on:
- **Settling Phase**: First 7 days of the month.
- **Stable Balance**: Daily Allowance >= 90% of Burn Rate.
- **Light Attention**: Allowance < 50% of Burn Rate.
- **Critical**: Allowance <= 0.

### 2. Dynamic Budgeting (`budget_provider.dart`)
Budgets in Fyne are **Soft Limits**.
- Logic calculates a **Daily Allowance** based on `(Total Budget - Spent) / Days Remaining`.
- Allows for flexible spending: saving today increases space tomorrow.

### 3. Financial Insights (`insights_provider.dart`)
Separates **Information** (Income vs Expenses) from **Evaluation** (Net Difference).
- **Burn Rate**: Tracks the velocity of spending over the last 30 days.
- **Net Worth History**: Dynamic calculation based on transaction ledger.

---

## 📂 Project Structure (`lib/`)

| Directory | Role | Key Files |
| :--- | :--- | :--- |
| **`providers/`** | **Business Logic & State**. The brain of the app. | `home_state_provider.dart`, `budget_provider.dart`, `account_provider.dart` |
| **`services/`** | **Infrastucture**. Crypto, API, IO. | `crypto_service.dart`, `api_service.dart`, `categorization_service.dart` |
| **`models/`** | **Data Structure**. Isar collections. | `account.dart`, `transaction.dart`, `budget.dart` |
| **`screens/`** | **Views**. Page-level composition. | `wallet_screen.dart` (Home), `insights_screen.dart` |
| **`widgets/`** | **Components**. Reusable UI elements. | `home_compass_widget.dart`, `transaction_item.dart` |

---

## 👨‍💻 Developer Protocols

### State Management (Riverpod)
- **Prefer `AsyncNotifier`**: For all data fetching/mutating states (Accounts, Budgets).
- **Use `Provider`**: For computed/derived state (like `HomeState` or `DailyAllowance`).
- **Immutable State**: Always use `.copyWith()` patterns.

### Coding Standards
- **Strict Typing**: No `dynamic` unless absolutely necessary (e.g. JSON parsing).
- **Absolute Paths**: Imports should use project-absolute paths.
- **English Code, Italian UI**: Code comments and variable names in English. UI strings in Italian.

### Design Implementation
- **Spacing**: Use standard grid multiples (4, 8, 16, 24, 32).
- **Text Styles**: Use `GoogleFonts.lora` for hero/display, `GoogleFonts.inter` for UI/body.
- **Colors**: Define colors in constants (or use the designated hex codes consistent with the theme).

---

## 🚀 Setup & Commands

### Prerequisites
- Flutter SDK 3.x
- Backend running (for Sync features) or Local Mode.

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Code Generation
**Mandatory** after editing any provider or model:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run App
```bash
flutter run
```

### 4. Build for Release (iOS)
```bash
flutter build ios --release --no-codesign
```

---

*> "Complexity involves a lot of moving parts. Simplicity involves a lot of moving parts that move as one."*
