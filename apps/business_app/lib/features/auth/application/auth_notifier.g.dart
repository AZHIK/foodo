// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the multi-profile authentication lifecycle.
///
/// Every transition mutates the single [AuthState] value that the router
/// redirects on. Methods return `null` on success and a [Failure] on
/// error, so screens can surface errors without the state machine having
/// to model transient error states.
///
/// ## PIN lockout
///
/// A profile that accumulates [AppDurations.maxPinAttempts] consecutive
/// failed PIN attempts is locked: [AuthState.pinLockedOut] and the
/// persisted `pin_locked_until` column (effectively indefinite, see
/// [AppDurations.pinLockoutIndefinite]). While locked, no Argon2id
/// verification is even attempted. The only resolution is full OTP
/// re-verification ([startLockoutResolution] / [completeLockoutResolution]),
/// which resets the counters and forces a NEW PIN.

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// Drives the multi-profile authentication lifecycle.
///
/// Every transition mutates the single [AuthState] value that the router
/// redirects on. Methods return `null` on success and a [Failure] on
/// error, so screens can surface errors without the state machine having
/// to model transient error states.
///
/// ## PIN lockout
///
/// A profile that accumulates [AppDurations.maxPinAttempts] consecutive
/// failed PIN attempts is locked: [AuthState.pinLockedOut] and the
/// persisted `pin_locked_until` column (effectively indefinite, see
/// [AppDurations.pinLockoutIndefinite]). While locked, no Argon2id
/// verification is even attempted. The only resolution is full OTP
/// re-verification ([startLockoutResolution] / [completeLockoutResolution]),
/// which resets the counters and forces a NEW PIN.
final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthState> {
  /// Drives the multi-profile authentication lifecycle.
  ///
  /// Every transition mutates the single [AuthState] value that the router
  /// redirects on. Methods return `null` on success and a [Failure] on
  /// error, so screens can surface errors without the state machine having
  /// to model transient error states.
  ///
  /// ## PIN lockout
  ///
  /// A profile that accumulates [AppDurations.maxPinAttempts] consecutive
  /// failed PIN attempts is locked: [AuthState.pinLockedOut] and the
  /// persisted `pin_locked_until` column (effectively indefinite, see
  /// [AppDurations.pinLockoutIndefinite]). While locked, no Argon2id
  /// verification is even attempted. The only resolution is full OTP
  /// re-verification ([startLockoutResolution] / [completeLockoutResolution]),
  /// which resets the counters and forces a NEW PIN.
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authNotifierHash() => r'215554bd41996cbdfdd5094561a01d1bdf126459';

/// Drives the multi-profile authentication lifecycle.
///
/// Every transition mutates the single [AuthState] value that the router
/// redirects on. Methods return `null` on success and a [Failure] on
/// error, so screens can surface errors without the state machine having
/// to model transient error states.
///
/// ## PIN lockout
///
/// A profile that accumulates [AppDurations.maxPinAttempts] consecutive
/// failed PIN attempts is locked: [AuthState.pinLockedOut] and the
/// persisted `pin_locked_until` column (effectively indefinite, see
/// [AppDurations.pinLockoutIndefinite]). While locked, no Argon2id
/// verification is even attempted. The only resolution is full OTP
/// re-verification ([startLockoutResolution] / [completeLockoutResolution]),
/// which resets the counters and forces a NEW PIN.

abstract class _$AuthNotifier extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
