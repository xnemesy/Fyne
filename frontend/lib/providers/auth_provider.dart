import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/crypto_service.dart';
import '../services/api_service.dart';

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
    if (user != null) {
      final hasKey = await _storage.read(key: 'fyne_rsa_private_key') != null;
      if (hasKey) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        // User is logged in but keys are missing (should not happen if flow is correct)
        state = AuthState(status: AuthStatus.unauthenticated, user: user);
      }
    } else {
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
      // Mock for now until Google Sign In is fully configured in console
      await Future.delayed(const Duration(seconds: 1)); 
      await _initializeUserKeys();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _initializeUserKeys();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> _initializeUserKeys() async {
    state = state.copyWith(status: AuthStatus.initializingKeys);
    try {
      final publicKey = await _crypto.getOrGeneratePublicKey();
      final api = ref.read(apiServiceProvider);
      
      // Send Public Key to Backend
      try {
        await api.post('/api/users/init', data: {
          'publicKey': publicKey,
          'email': _auth.currentUser?.email ?? 'anonymous_${_auth.currentUser?.uid}',
        });
      } catch (apiErr) {
        print("Backend init error: $apiErr");
        // We continue anyway if it's a local demo
      }

      state = AuthState(status: AuthStatus.authenticated, user: _auth.currentUser);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: "Errore generazione chiavi: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _storage.delete(key: 'fyne_rsa_private_key'); // Clear key on signout for security
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
