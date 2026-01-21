import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptography/cryptography.dart';

/// The master key provider. 
/// In a real app, this is derived once at login and kept in secure memory.
/// This key is used for AES-256 local encryption.
final masterKeyProvider = StateProvider<SecretKey?>((ref) => null);
