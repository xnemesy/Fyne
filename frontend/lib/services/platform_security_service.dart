import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class PlatformSecurityService {
  static const _channel = MethodChannel('com.fyne.app/security');

  /// Toggles the OS-level secure screen flag (Android only).
  /// This prevents screenshots, screen recording, and shows a blank/blurred 
  /// screen in the task switcher.
  Future<void> setSecureScreen(bool secure) async {
    if (defaultTargetPlatform != TargetPlatform.android || kDebugMode) return;
    
    try {
      await _channel.invokeMethod('setSecureScreen', {'secure': secure});
      debugPrint('[PlatformSecurity] FLAG_SECURE set to: $secure');
    } on PlatformException catch (e) {
      debugPrint('[PlatformSecurity] Failed to set FLAG_SECURE: ${e.message}');
    }
  }
}
