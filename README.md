# Fyne: Zero-Knowledge Financial Intelligence 🛡️🏛️

Fyne is a premium personal finance application designed with a **Privacy-First, Zero-Knowledge architecture**. It provides a high-end editorial user experience for managing assets, budgets, and transactions while ensuring that financial data remains strictly under the user's control.

---

# 🤖 Developer & Agent Documentation

> **Note for AI Agents**: This repository is optimized for autonomous coding and "Power User" UX patterns. Read this section carefully before modifying code.

## 🧠 System Architecture

Fyne follows a strict **Privacy-by-Design** philosophy. The backend is "blind"; it sees only encrypted blobs.

### 🔐 Cryptographic Models
1.  **Local AES-256 (GCM)**: Used for manually entered data. Keys are derived/stored on-device in Secure Storage.
2.  **Hybrid RSA-2048 Sync**: Used for Banking Sync. 
    - The client generates an RSA key pair.
    - The Public Key is shared with the backend.
    - The backend (via GoCardless/Tink) encrypts incoming bank feeds using the user's Public Key.
    - **Result**: Even the backend developer cannot read bank transactions; only the original device holds the Private Key.

### 🔧 Tech Stack (Frontend)
- **Framework**: Flutter (Dart 3.x)
- **State Management**: **Riverpod 2.0** (with `riverpod_generator`)
- **Local Database**: **Isar** (NoSQL, Typed, Async)
- **ML Engine**: `tflite_flutter` (Local inference for categorization)
- **UI Framework**: Custom "Neo-Minimalist" Design System (Glassmorphism, Lora/Inter typography)

---

## 🧭 UX Philosophy: The Rule of Silence

Fyne follows a "Digital Luxury" UX model where the app only speaks when necessary.

- **Journey Guidance**: Managed via `guidanceProvider`. It determines if the user is in *Onboarding*, *Data Collection*, *Budgeting*, or *Mature* stage.
- **The Rule of Silence**: Once in the *Mature* stage, all "intelligence" messages and empty states disappear. The absence of noise is a premium feature.
- **Milestone Feedback**: Persistent micro-feedback (e.g., "System Initialized") is shown only once per device using `preferencesProvider` backended by `FlutterSecureStorage`.
- **Power User First**: No hand-holding, no generic Material icons. Every interaction must feel intentional and technical.

---

## 📂 Project Structure Map (`/frontend`)

| Directory | Purpose | Agent Rule |
| :--- | :--- | :--- |
| `lib/models/` | Data definitions & Isar Collections | **Must** be properly typed. |
| `lib/providers/` | Riverpod State & Guidance Logic | Use `@riverpod` annotations. |
| `lib/services/` | Core logic (Auth, Crypto, Banking) | Use `CryptoService` for all sensitive I/O. |
| `lib/screens/` | Feature pages | Editorial UI focus. No placeholders. |
| `lib/widgets/` | Reusable components | Maintain "Neo-Minimalist" consistency. |

---

## ⚡ Quick Start & Commands

### 1. Setup Environment
```bash
flutter pub get
# Copy .env.example to .env for backend if working on banking
```

### 2. Code Generation (Riverpod/Isar)
**Mandatory** after editing any provider or model:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Banking Setup
Fyne supports real-world connections via **GoCardless** and **Tink**.
- Backend keys are required in `backend/.env`.
- Ensure RSA keys are initialized via `authProvider` before attempting a sync.

---

## 🛡️ Security & Privacy Protocols (NON-NEGOTIABLE)

1.  **Zero-Knowledge Integrity**: 
    - The server **never** receives `amount`, `title`, or `description` in plain text.
    - Encryption happens **locally** before network transmission.
2.  **Silent Analytics**:
    - No external trackers (Firebase Analytics/Sentry) should log PII (Personally Identifiable Information).
3.  **Local ML Only**:
    - Do **not** send transaction strings to external analysis APIs (e.g. OpenAI) unless explicitly anonymized.

---

## 🎨 Design Guidelines
- **Typography**: Headers/Hero Numbers = `Lora` (Serif), Technical Body = `Inter` (Sans).
- **Aesthetics**: High contrast, subtle glassmorphism, minimal use of color (only for state, e.g., Green/Red/Gold).
- **Hierarchy**: The data (numbers) is the protagonist. Status labels are secondary.
