// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountSyncRepository)
const accountSyncRepositoryProvider = AccountSyncRepositoryProvider._();

final class AccountSyncRepositoryProvider extends $FunctionalProvider<
    AccountSyncRepository,
    AccountSyncRepository,
    AccountSyncRepository> with $Provider<AccountSyncRepository> {
  const AccountSyncRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountSyncRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountSyncRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountSyncRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountSyncRepository create(Ref ref) {
    return accountSyncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountSyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountSyncRepository>(value),
    );
  }
}

String _$accountSyncRepositoryHash() =>
    r'fce0ce13046db89619da8ce0b65d7b650960993d';
