import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/account_sync_repository.dart';

part 'account_sync_provider.g.dart';

@riverpod
AccountSyncRepository accountSyncRepository(Ref ref) {
  return AccountSyncRepository(ref);
}
