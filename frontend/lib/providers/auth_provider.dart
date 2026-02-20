import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import '../services/crypto_service.dart';
import '../services/seed_service.dart';
import 'master_key_provider.dart';
import 'storage_provider.dart';

import 'dart:async';
import 'package:flutter/widgets.dart';

enum AuthStatus {
  unauthenticated,
  authenticated, // Logged in and vault UNLOCKED
  locked, // Logged in but vault LOCKED (RAM wiped)
  setupRequired, // Logged in but wizard not completed (no seed phrase)
  signingIn,
  initializingKeys,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  AuthState({required this.status, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState>
    with WidgetsBindingObserver {
  final Ref ref;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();
  late final FlutterSecureStorage _storage;
  late final CryptoService _crypto;

  Timer? _idleTimer;
  static const _idleTimeout = Duration(minutes: 5);
  static const _autoPassphraseKey = 'fyne_auto_passphrase';
  static const _seedHashKey = 'fyne_seed_hash';
  final _seedService = SeedService();

  AuthNotifier(this.ref)
      : super(AuthState(status: AuthStatus.unauthenticated)) {
    _storage = ref.read(secureStorageProvider);
    _crypto = ref.read(cryptoServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    _checkInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    // FIX: Only lock on PAUSED (background), not INACTIVE (biometric prompt/overlays)
    // This prevents race condition during wizard completion/biometric setup
    if (appState == AppLifecycleState.paused) {
      if (kDebugMode) {
        debugPrint(
            "[Auth] App entered background (PAUSED). Wiping sensitive RAM.");
      }
      _lockVault();
    } else if (appState == AppLifecycleState.inactive) {
      if (kDebugMode) {
        debugPrint(
            "[Auth] App triggers INACTIVE state (likely Biometric/Overlay). Ignored.");
      }
    }
  }

  /// Resets the idle timer on user interaction
  void resetIdleTimer() {
    _idleTimer?.cancel();
    if (state.status == AuthStatus.authenticated) {
      _idleTimer = Timer(_idleTimeout, () {
        if (kDebugMode) {
          debugPrint("[Auth] Idle timeout reached. Locking vault.");
        }
        _lockVault();
      });
    }
  }

  void _lockVault() {
    debugPrint(
        "🔐 [AUTH] _lockVault() triggered. Wiping keys and locking vault.");
    _crypto.wipe();
    ref.read(masterKeyProvider.notifier).state = null;
    if (state.status == AuthStatus.authenticated) {
      state = state.copyWith(status: AuthStatus.locked);
      debugPrint("🔐 [AUTH] Vault status set to LOCKED.");
    }
  }

  /// Gets or generates an auto-passphrase stored in SecureStorage.
  /// This is the Opzione A approach: transparent to the user.
  Future<String> _getOrCreateAutoPassphrase() async {
    String? existing = await _storage.read(key: _autoPassphraseKey);
    if (existing != null) return existing;

    // Generate a random 32-byte passphrase
    final randomKey = await SecretKeyData.random(length: 32);
    final passphrase = base64.encode(randomKey.bytes);
    await _storage.write(key: _autoPassphraseKey, value: passphrase);

    if (kDebugMode) {
      debugPrint("[Auth] Auto-passphrase generated and persisted.");
    }
    return passphrase;
  }

  /// Unlocks the vault and populates masterKeyProvider.
  /// Returns true if successful.
  Future<bool> _unlockAndPopulateMasterKey(
      String passphrase, String userId) async {
    debugPrint("🔐 [AUTH] Attempting to unlock vault for user: $userId");
    try {
      await _crypto.unlock(passphrase, userId);
      final dbKey = await _crypto.getScopedKey(EncryptionScope.database);
      ref.read(masterKeyProvider.notifier).state = dbKey;

      debugPrint(
          "🔐 [AUTH] Vault unlocked successfully. masterKeyProvider populated.");
      return true;
    } catch (e) {
      debugPrint("🔐 [AUTH] CRITICAL: Vault unlock failed: $e");
      return false;
    }
  }

  Future<void> _checkInitialState() async {
    final user = _auth.currentUser;
    if (kDebugMode) {
      debugPrint(
          "[Auth] Checking initial state. Current user: ${user?.uid ?? 'None'}");
    }

    if (user != null) {
      final hasRsaKey =
          await _storage.read(key: 'fyne_rsa_private_key') != null;
      final hasVaultSalt = await _storage.read(key: 'fyne_vault_salt') != null;
      final hasSeedHash = await _storage.read(key: _seedHashKey) != null;

      if (!hasSeedHash) {
        // User logged in but never completed the wizard → force setup
        if (kDebugMode) {
          debugPrint("[Auth] No seed hash found. Wizard required.");
        }
        state = AuthState(status: AuthStatus.setupRequired, user: user);
        return;
      }

      if (hasRsaKey && hasVaultSalt && _crypto.isUnlocked) {
        // Already unlocked (warm restart) - just populate masterKey
        final dbKey = await _crypto.getScopedKey(EncryptionScope.database);
        ref.read(masterKeyProvider.notifier).state = dbKey;
        state = AuthState(status: AuthStatus.authenticated, user: user);
        resetIdleTimer();
      } else if (hasRsaKey && hasVaultSalt) {
        // Keys exist but vault is locked - auto-unlock with stored passphrase
        final passphrase = await _storage.read(key: _autoPassphraseKey);
        if (passphrase != null) {
          final success =
              await _unlockAndPopulateMasterKey(passphrase, user.uid);
          if (success) {
            state = AuthState(status: AuthStatus.authenticated, user: user);
            resetIdleTimer();
          } else {
            state = AuthState(status: AuthStatus.locked, user: user);
          }
        } else {
          state = AuthState(status: AuthStatus.locked, user: user);
        }
      } else {
        // Has seed hash but keys missing (e.g. reinstall) → need recovery
        debugPrint("[Auth] Keys missing but seed hash exists. Setup required.");
        state = AuthState(status: AuthStatus.setupRequired, user: user);
      }
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail(String email, String password,
      {bool isSignUp = false, String? masterPassword}) async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      if (isSignUp) {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        // New user → route to wizard
        state = AuthState(
            status: AuthStatus.setupRequired, user: _auth.currentUser);
      } else {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        final user = _auth.currentUser;
        if (user != null) {
          final hasSeedHash = await _storage.read(key: _seedHashKey) != null;
          if (!hasSeedHash) {
            // Never completed wizard
            state = AuthState(status: AuthStatus.setupRequired, user: user);
            return;
          }
          final passphrase = await _storage.read(key: _autoPassphraseKey);
          if (passphrase != null) {
            final success =
                await _unlockAndPopulateMasterKey(passphrase, user.uid);
            if (success) {
              state = AuthState(status: AuthStatus.authenticated, user: user);
              resetIdleTimer();
            } else {
              state = AuthState(status: AuthStatus.locked, user: user);
            }
          } else {
            state = AuthState(status: AuthStatus.locked, user: user);
          }
        }
      }
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final hasSeedHash = await _storage.read(key: _seedHashKey) != null;
        if (!hasSeedHash) {
          // New Google user → wizard
          state = AuthState(status: AuthStatus.setupRequired, user: user);
          return;
        }
        // Existing user → auto-unlock
        final passphrase = await _storage.read(key: _autoPassphraseKey);
        if (passphrase != null) {
          final success =
              await _unlockAndPopulateMasterKey(passphrase, user.uid);
          if (success) {
            state = AuthState(status: AuthStatus.authenticated, user: user);
            resetIdleTimer();
          } else {
            state = AuthState(status: AuthStatus.locked, user: user);
          }
        } else {
          state = AuthState(status: AuthStatus.locked, user: user);
        }
      }
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> unlockVault(String passphrase) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _crypto.unlock(passphrase, user.uid);
      final dbKey = await _crypto.getScopedKey(EncryptionScope.database);
      ref.read(masterKeyProvider.notifier).state = dbKey;
      state = AuthState(status: AuthStatus.authenticated, user: user);
      resetIdleTimer();
    } catch (e) {
      // Also try auto-passphrase as fallback
      final autoPassphrase = await _getOrCreateAutoPassphrase();
      final success =
          await _unlockAndPopulateMasterKey(autoPassphrase, user.uid);
      if (success) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        resetIdleTimer();
      } else {
        state = state.copyWith(error: "Passphrase errata o errore sblocco.");
      }
    }
  }

  /// Called by the MasterKeyWizard after seed verification.
  /// Converts mnemonic → passphrase, initializes keys, and transitions to authenticated.
  Future<void> completeWizardSetup(String mnemonic,
      {bool biometricEnabled = false}) async {
    debugPrint("🔐 [AUTH] Starting wizard completion flow...");
    state = state.copyWith(status: AuthStatus.initializingKeys);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // 1. Derive deterministic passphrase from mnemonic
      final passphrase = _seedService.mnemonicToPassphrase(mnemonic);

      // 2. Save passphrase to SecureStorage for auto-unlock
      debugPrint("🔐 [AUTH] Saving auto-passphrase to storage...");
      await _storage.write(key: _autoPassphraseKey, value: passphrase);

      // 3. Save seed hash as "wizard completed" flag
      final seedHash = _seedService.hashMnemonic(mnemonic);
      debugPrint("🔐 [AUTH] Saving seed hash: $seedHash");
      await _storage.write(key: _seedHashKey, value: seedHash);

      // iOS HARDENING: Force a delay to allow Keychain to flush
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint(
            "🔐 [AUTH] iOS detected: Waiting 500ms for Keychain flush...");
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // P0 DEBUG: Strict Persistence Verification
      debugPrint("🔐 [AUTH] P0: Strict persistence verification...");
      final verifyPass = await _storage.read(key: _autoPassphraseKey);
      final verifyHash = await _storage.read(key: _seedHashKey);

      if (verifyPass == null || verifyHash == null) {
        debugPrint(
            "🔐 [AUTH] ❌ CRITICAL: Storage write verified FAILED after delay!");
        throw Exception(
            "Keychain Persistence Error: Keys not found after write. Check iOS Accessibility settings.");
      }
      debugPrint(
          "🔐 [AUTH] ✅ P0: Storage persistence verified. Keys: pass=true, hash=true");

      // 4. Save biometric preference
      await _storage.write(
          key: 'fyne_biometric_enabled', value: biometricEnabled.toString());

      // 5. Initialize RSA Keys
      debugPrint("🔐 [AUTH] Initializing RSA keys...");
      final publicKey = await _crypto.getOrGeneratePublicKey();

      // 6. Unlock vault with passphrase
      debugPrint("🔐 [AUTH] Unlocking vault with new passphrase...");
      await _crypto.unlock(passphrase, user.uid);

      // 7. Populate masterKeyProvider
      final dbKey = await _crypto.getScopedKey(EncryptionScope.database);
      ref.read(masterKeyProvider.notifier).state = dbKey;

      // 8. Link identity to Firestore
      debugPrint("🔐 [AUTH] Linking identity to Firestore...");
      await _firestore.collection('users').doc(user.uid).set({
        'rsaPublicKey': publicKey,
        'email': user.email ?? 'anonymous_${user.uid}',
        'lastSync': FieldValue.serverTimestamp(),
        'hasMasterPassword': true,
      }, SetOptions(merge: true));

      debugPrint(
          "🔐 [AUTH] 🏁 Wizard setup COMPLETE. Vault authenticated and unlocked.");

      state = AuthState(status: AuthStatus.authenticated, user: user);
      resetIdleTimer();
    } catch (e, stack) {
      debugPrint("🔐 [AUTH] ❌ Wizard setup FAILED: $e");
      debugPrint(stack.toString());
      state = state.copyWith(
          status: AuthStatus.setupRequired, error: "Errore configurazione: $e");
    }
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      await _auth.signInAnonymously();
      // Don't auto-initialize: route to wizard
      state =
          AuthState(status: AuthStatus.setupRequired, user: _auth.currentUser);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Zero-Persistence Wipe
    _crypto.wipe();
    ref.read(masterKeyProvider.notifier).state = null;
    _idleTimer?.cancel();

    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<String?> exportPrivateKey() async {
    return await _storage.read(key: 'fyne_rsa_private_key');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
