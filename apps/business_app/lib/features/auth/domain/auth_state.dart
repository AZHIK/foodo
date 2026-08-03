import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/storage/app_database.dart';

part 'auth_state.freezed.dart';

/// Sealed representation of the multi-profile authentication lifecycle.
///
/// This is the single source of truth the router redirects on, so every
/// reachable destination is driven by exactly one [AuthState].
///
/// The state machine flows:
///
/// ```text
/// unauthenticated ──requestOtp──> otpPending ──verifyOtp──> settingPin
///     │                                                    │
///     │                                              setPin │
///     │                                                      v
///     └────────────<────────── profilesAvailable <── sessionActive
///                                     │
///                              activateProfile ───────────> sessionActive
///                                     │
///                              (wrong PIN x5) ──────────> pinLockedOut
///                                     │
///                              OTP re-verify ──────────> settingPin (new PIN)
/// ```
@freezed
sealed class AuthState with _$AuthState {
  const AuthState._();

  /// No profiles exist on this device yet — first-run OTP login.
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// One or more profiles exist; the user must pick one (and enter its
  /// PIN) to start a shift.
  const factory AuthState.profilesAvailable(
    List<LocalUserProfile> profiles,
  ) = ProfilesAvailable;

  /// A profile is currently active.
  ///
  /// [locked] is true while the app is waiting for the PIN to be
  /// re-entered after backgrounding past the inactivity timeout.
  const factory AuthState.sessionActive(
    LocalUserProfile profile, {
    @Default(false) bool locked,
  }) = SessionActive;

  /// An OTP has been requested for [phone]; waiting for the code.
  const factory AuthState.otpPending(String phone) = OtpPending;

  /// OTP verified; the user must choose a PIN before the session starts.
  const factory AuthState.settingPin({
    required String phone,
    required String userId,
    required String refreshToken,
  }) = SettingPin;

  /// Profile [profile] has exceeded [AppDurations.maxPinAttempts] failed
  /// PIN attempts. PIN entry is blocked until [lockedUntil] passes (in
  /// practice the persisted value is effectively indefinite) and the user
  /// completes OTP re-verification, after which they must set a NEW PIN.
  const factory AuthState.pinLockedOut(
    LocalUserProfile profile,
    DateTime lockedUntil,
  ) = PinLockedOut;
}
