import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Global index for bottom navigation state.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
