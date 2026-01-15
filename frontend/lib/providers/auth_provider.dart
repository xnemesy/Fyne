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

  Future<void> signInWithGoogle() async {
    // Implementation for Google Sign In
    // For now, using a mock/placeholder flow as requested for the UI
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      // Logic for Google Sign In would go here
      // For demo purposes, we trigger the key generation after a simulated sign in
      await Future.delayed(const Duration(seconds: 1)); 
      // await _auth.signInWithCredential(...);
      await _initializeUserKeys();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.signingIn);
    try {
      // Logic for Apple Sign In would go here
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
      await api.post('/api/users/init', data: {
        'publicKey': publicKey,
        'email': _auth.currentUser?.email,
      });

      state = AuthState(status: AuthStatus.authenticated, user: _auth.currentUser);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: "Errore generazione chiavi: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
