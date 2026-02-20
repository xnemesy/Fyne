import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const fyneSecureStorageOptions = IOSOptions(
  accountName: 'fyne_secure_storage',
  accessibility: KeychainAccessibility.first_unlock_this_device,
  synchronizable: false,
);

const fyneAndroidStorageOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

/// Provider for a centralized [FlutterSecureStorage] instance.
/// Using a singleton ensures consistent access to the same keychain/preferences.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    iOptions: fyneSecureStorageOptions,
    aOptions: fyneAndroidStorageOptions,
  );
});
