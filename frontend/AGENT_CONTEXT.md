# Fyne App - Technical Specifications & Agent Context

This document is specifically tailored for AI Coding Assistants and Agents to understand the architecture, constraints, and technological choices of the "Fyne" project.

## 1. Project Overview & Core Philosophy
**Fyne** is an ultra-privacy-focused personal finance management application. 
- **Zero-Knowledge Architecture:** No sensitive financial data (amounts, descriptions, account balances) is ever stored in plain text, neither locally nor remotely.
- **Offline-First:** All operations work completely offline.
- **No-AI/ML Constraints:** Categorization relies strictly on deterministic keyword matching, not on machine learning models (e.g., TensorFlow, MLKit).

## 2. Tech Stack Setup
- **Framework:** Flutter 3.x (Dart 3.x)
- **State Management:** Riverpod (code-generation approach using `@riverpod` annotations and `riverpod_generator`).
- **Local Database:** Isar (specifically `isar_community` fork v3.3.0 for modern analyzer support).
- **Backend Services:** Firebase (Authentication, Analytics, Crashlytics, Firestore solely for encrypted blob syncing).
- **Security:** `flutter_secure_storage` for storing salts/keys, `local_auth` for biometrics, `cryptography` package for AES-256-GCM and Argon2/PBKDF2 key derivation.

## 3. Security & Cryptography Model
- **Encryption Scope:** Field-level encryption. Isar stores objects where sensitive fields (`encryptedAmount`, `encryptedDescription`, `encryptedBalance`) are `String` types containing AES-GCM + HMAC payload blocks.
- **Key Derivation:** The User's Master Key is derived from a User Passphrase + Salt.
- **Secure Storage:** The generated Vault Passphrase and derived keys are stored in the device's Secure Enclave (`flutter_secure_storage`).
- **Key Rotation:** A `KeyRotationService` handles lazy migration of database items when the cryptographic cipher/version is updated.
- **Runtime:** `CryptoService` handles encryption/decryption. The `masterKey` resides only in RAM and drops on app pause/exit.

## 4. Architecture (Clean Architecture Pattern)
The project is strictly separated into layers.
- **`lib/models/`**: Isar schema definitions (`@collection`).
- **`lib/data/repositories/`**: Abstraction layer integrating Isar and `CryptoService`. Example: `TransactionRepository` accepts an encrypted model and transparently decrypts it via `CryptoService` before returning to the domain.
- **`lib/services/`**: Low-level singleton or scoped providers (`SyncService`, `BackupService`, `CryptoService`, `KeyRotationService`).
- **`lib/providers/`**: Riverpod state management. UI interacts **ONLY** with providers, never directly with repositories. (e.g., `accountOverviewProvider`, `syncProvider`).
- **`lib/presentation/`**: Flutter UI. Further split into `/screens` and `/widgets`.
- **`lib/core/`**: App-wide configurations, constants, theme (`FyneTheme`), and extension methods.

## 5. Performance Constraints
- **Pagination Strategy:** Isar runs synchronous DB operations fast, but decrypting thousands of records blocks the UI isolate. Always use `offset`/`limit` (usually 50 items) for UI lists. 
- **Background Isolates:** Batch decryption operations (like calculating Total Net Worth from 10k transactions) are offloaded to Dart Isolates / compute functions.

## 6. UI/UX Rules
- **Theming:** Forced Dark Mode (`ThemeMode.dark`). Palette is highly editorial, minimalist. 
- **Typography:** Uses serif fonts and specific system UI handling (SafeAreas strictly respected, no white blinding splash screens).
- **Riverpod strictly enforced:** Avoid `setState` replacing it with Notifier/StateProviders wherever possible. `ConsumerWidget` and `ConsumerStatefulWidget` are the standard.

## 7. Strict AI Coding Rules for this Codebase
1. **Never suggest ML/AI packages** (No TFLite, OpenAI, Gemini inside the app logic).
2. **Never store plain text amounts/names in Isar variables**. If you generate a Model, financial fields must be mapped as `String encryptedAmount`. Update the `.g.dart` files via `flutter pub run build_runner build --delete-conflicting-outputs`.
3. **Handle AsyncValue errors:** UI widgets reading providers must gracefully handle `.when(data: , loading: , error: )`.
4. **Assume Crypto failure:** When writing decryption logic, assume MAC validation could fail and write error fallback cases.

---
*End of Context.*
