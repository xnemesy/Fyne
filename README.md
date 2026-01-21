# Fyne: Zero-Knowledge Financial Intelligence 🛡️🏛️

Fyne is a premium personal finance application designed with a **Privacy-First, Zero-Knowledge architecture**. It provides a high-end editorial user experience for managing assets, budgets, and transactions while ensuring that financial data remains strictly under the user's control.

---

# 🤖 Developer & Agent Documentation

> **Note for AI Agents**: This repository is optimized for autonomous coding. Read this section carefully before modifying code.

## 🧠 System Architecture

Fyne follows a strict **Privacy-by-Design** philosophy. The backend is "blind"; it sees only encrypted blobs. All business logic requiring clear-text data (categorization, budget calc, heuristics) happens **locally on the device**.

### 🔧 Tech Stack (Frontend)
- **Framework**: Flutter (Dart 3.x)
- **State Management**: **Riverpod 2.0** (with `riverpod_generator`)
- **Local Database**: **Isar** (NoSQL, Typed, Async)
- **Cryptography**: `cryptography` package (AES-GCM for data, RSA for sharing)
- **ML Engine**: `tflite_flutter` (Local inference)
- **UI Framework**: Custom "Neo-Minimalist" Design System (Glassmorphism, Lora/Inter typography)

### 📂 Project Structure Map (`/frontend`)
| Directory | Purpose | Agent Rule |
| :--- | :--- | :--- |
| `lib/models/` | Data definitions & Isar Collections | **Must** be properly typed. |
| `lib/providers/` | Riverpod State Logic | Use `@riverpod` annotations. Run `build_runner` after edits. |
| `lib/services/` | Core logic (Auth, Crypto, API) | **CRITICAL**: Use `CryptoService` for all sensitive I/O. |
| `lib/screens/` | Feature pages | Ensure "Premium" feel. No standard Material placeholders. |
| `lib/widgets/` | Reusable components | Maintain design consistency (Colors, Spacing). |

### 🧩 Available Skills (Agent Capabilities)
This repository includes specialized skill definitions in `.agent/skills/`. **Usage is mandatory** for the relevant tasks:
- `flutter-clean-architecture`: Validating layer separation.
- `flutter-riverpod-architecture`: implementing new providers.
- `flutter-secure-storage-pattern`: Managing secure tokens/keys.
- `node-express-backend`: Modifying the `/backend` service.

---

## ⚡ Quick Start & Commands

### 1. Setup Environment
```bash
# Clone
git clone [repo-url]
cd Fyne/frontend

# Install Dependencies
flutter pub get
```

### 2. Code Generation (Riverpod/Isar)
Since we use code generation, **you must run this command** after creating/editing models or providers:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run Application
```bash
flutter run
# Specific to iOS Simulator (if issues arise)
flutter build ios --debug --no-codesign --simulator
```

---

## �️ Security & Privacy Protocols (NON-NEGOTIABLE)

1.  **Zero-Knowledge Integrity**: 
    - The server **never** receives `amount`, `title`, or `description` in plain text.
    - Encryption happens in `CryptoService` **before** API calls.
    - Decryption happens **only** at render time on the client.

2.  **Sensitive Data Logging**:
    - **FORBIDDEN**: `print(transaction.amount)`
    - **ALLOWED**: `print('Transaction sync completed: ${ids.length} items')`

3.  **Local ML**:
    - Transaction categorization is performed by `tflite`.
    - Do **not** send transaction strings to external analysis APIs (e.g. OpenAI) unless explicitly anonymized.

---

## 🎨 Design Guidelines
- **Typography**: Headers = `Lora` (Serif), Body/Numbers = `Inter` (Sans).
- **Colors**: Use the defined `AppTheme` palette. Avoid hardcoding hex values.
- **Interactions**: Prefer clear, gestural interactions (Swipe, Tap, Long Press).
