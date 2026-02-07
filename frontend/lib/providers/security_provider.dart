import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'preferences_provider.dart';

class SecurityState {
  final bool canCheckBiometrics;
  final bool isSupported;
  final List<BiometricType> availableBiometrics;

  SecurityState({
    this.canCheckBiometrics = false,
    this.isSupported = false,
    this.availableBiometrics = const [],
  });

  SecurityState copyWith({
    bool? canCheckBiometrics,
    bool? isSupported,
    List<BiometricType>? availableBiometrics,
  }) {
    return SecurityState(
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      isSupported: isSupported ?? this.isSupported,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
    );
  }
}

class SecurityNotifier extends Notifier<SecurityState> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  SecurityState build() {
    _init();
    return SecurityState();
  }

  Future<void> _init() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    final List<BiometricType> available = await _auth.getAvailableBiometrics();

    state = SecurityState(
      canCheckBiometrics: canCheck,
      isSupported: isSupported,
      availableBiometrics: available,
    );
  }

  Future<bool> authenticate({String reason = 'Autenticati per accedere al tuo Vault'}) async {
    // Only authenticate if preferences say so or if we are explicitly asking (during setup)
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Fallback to PIN/Passcode enabled
        ),
      );
    } catch (e) {
      debugPrint("Auth Error: $e");
      return false;
    }
  }
}

final securityProvider = NotifierProvider<SecurityNotifier, SecurityState>(() => SecurityNotifier());
