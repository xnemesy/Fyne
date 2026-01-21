import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/crypto_service.dart';
import '../services/api_service.dart';
import 'master_key_provider.dart';
import 'budget_provider.dart';

enum AuthStatus {
  unauthenticated,
  authenticated,
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

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final _auth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage();
  final _crypto = CryptoService();

  AuthNotifier(this.ref) : super(AuthState(status: AuthStatus.unauthenticated)) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final user = _auth.currentUser;
    debugPrint("[Auth] Checking initial state. Current user: ${user?.uid ?? 'None'}");
    
    if (user != null) {
      final hasKey = await _storage.read(key: 'fyne_rsa_private_key') != null;
      debugPrint("[Auth] RSA Key present: $hasKey");
      
      if (hasKey) {
        // Restore Master Key to Riverpod state for decryption
        final masterKey = await _crypto.getOrGenerateMasterKey();
        final masterKeyFound = await _storage.read(key: 'fyne_master_key') != null;
        debugPrint("[Auth] MasterKey restored. Found in storage: $masterKeyFound");
        
        ref.read(masterKeyProvider.notifier).state = masterKey;
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        debugPrint("[Auth] Key missing, forcing re-initialization.");
        await _initializeUserKeys();
      }
    } else {
      debugPrint("[Auth] No user found.");
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail(String email, String password, {bool isSignUp = false}) async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      if (isSignUp) {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await _initializeUserKeys();
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        // On sign in, we check for keys in storage. If not there, the user might need to import them.
        // For this demo, we auto-init if missing.
        await _checkInitialState();
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      await _auth.signInAnonymously();
      await _initializeUserKeys();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      // In a real app we'd use GoogleSignIn()
      // For this demo we use anonymous auth as placeholder but update the state
      await _auth.signInAnonymously();
      await _initializeUserKeys();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      // In a real app we'd use SignInWithApple()
      await _auth.signInAnonymously();
      await _initializeUserKeys();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> _initializeUserKeys() async {
    state = state.copyWith(status: AuthStatus.initializingKeys);
    try {
      // 1. Initialize RSA Keys for Sync
      final publicKey = await _crypto.getOrGeneratePublicKey();
      
      // 2. Initialize AES Master Key for Local Encryption
      final masterKey = await _crypto.getOrGenerateMasterKey();
      ref.read(masterKeyProvider.notifier).state = masterKey;

      final api = ref.read(apiServiceProvider);
      
      try {
        debugPrint("[Auth] Sending init request to backend...");
        await api.post('/api/users/init', data: {
          'publicKey': publicKey,
          'email': _auth.currentUser?.email ?? 'anonymous_${_auth.currentUser?.uid}',
        });
        debugPrint("[Auth] Backend init successful.");
      } catch (apiErr) {
        debugPrint("[Auth] Backend init FAILED: $apiErr");
        String errorMessage = apiErr.toString();
        if (apiErr is DioException) {
          errorMessage = apiErr.response?.data?['error'] ?? apiErr.message;
        }
        state = state.copyWith(status: AuthStatus.unauthenticated, error: "Sync Error: $errorMessage");
        return; 
      }

      state = AuthState(status: AuthStatus.authenticated, user: _auth.currentUser);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: "Errore generazione chiavi: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _storage.delete(key: 'fyne_rsa_private_key'); // Clear RSA key
    // We do NOT delete the AES master key from storage as it encrypts local data which persists.
    // However, we clear it from memory.
    ref.read(masterKeyProvider.notifier).state = null;
    
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
