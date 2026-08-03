import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/token_store.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/identity_api.dart';
import '../data/local_profile_repository.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  // ── Boot ─────────────────────────────────────────────────────────
  /// Loads persisted profiles and any active session during splash.
  Future<void> initialize() async {
    final profiles =
        await ref.read(localProfileRepositoryProvider).listProfiles();

    final active = profiles.where((p) => p.isCurrentlyActive).firstOrNull;
    if (active != null) {
      if (_isLockedOut(active)) {
        state = AuthState.pinLockedOut(active, active.pinLockedUntil!);
      } else {
        state = AuthState.sessionActive(active, locked: true);
      }
    } else if (profiles.isNotEmpty) {
      state = AuthState.profilesAvailable(profiles);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  // ── First-run OTP login ─────────────────────────────────────────
  /// Requests an OTP for [phone]; moves to [AuthState.otpPending] only
  /// once the request succeeds.
  Future<Failure?> requestOtp(String phone) async {
    try {
      await ref.read(identityApiProvider).requestOtp(phone);
      state = AuthState.otpPending(phone);
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  /// Verifies the OTP code, caches the issued access token, and moves to
  /// [AuthState.settingPin] so the user can choose a device PIN before the
  /// session starts.
  Future<Failure?> verifyOtp(String phone, String code) async {
    try {
      final result = await ref.read(identityApiProvider).verifyOtp(phone, code);
      ref.read(tokenStoreProvider).accessToken = result.accessToken;
      state = AuthState.settingPin(
        phone: phone,
        userId: result.userId,
        refreshToken: result.refreshToken,
      );
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  /// Persists the new profile with its Argon2id [pin] hash, stores the
  /// refresh token keyed by user, and starts the session.
  ///
  /// For an existing profile (lockout resolution) the stored display name
  /// is preserved unless a new one is supplied.
  Future<Failure?> setPin({
    required String phone,
    required String userId,
    required String refreshToken,
    required String pin,
    String? displayName,
  }) async {
    try {
      final pinHash = await ref.read(pinServiceProvider).hashPin(pin);

      final existing =
          await ref.read(localProfileRepositoryProvider).profileById(userId);
      final resolvedName = displayName ?? existing?.displayName ?? phone;

      await ref.read(localProfileRepositoryProvider).upsertProfile(
            userId: userId,
            phone: phone,
            displayName: resolvedName,
            pinHash: pinHash,
          );

      await ref
          .read(secureStorageServiceProvider)
          .saveRefreshToken(userId: userId, token: refreshToken);

      state = AuthState.sessionActive(
        await ref.read(localProfileRepositoryProvider).activeProfile(),
        locked: false,
      );
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  // ── Existing-profile activation (pick + PIN) ────────────────────
  /// The profile the user selected on the picker, awaiting PIN entry on
  /// the unlock screen. Consulted by the router so `/pin-unlock` is
  /// reachable while [AuthState.profilesAvailable].
  String? _pendingProfileId;

  /// Profile awaiting PIN entry after selection on the picker, if any.
  String? get pendingProfileId => _pendingProfileId;

  /// Remembers [userId] so the PIN unlock screen knows which profile to
  /// activate once the user submits a PIN.
  void selectProfileForUnlock(String userId) {
    _pendingProfileId = userId;
  }

  /// Activates an existing profile after verifying its [pin].
  ///
  /// When the profile is locked out this transitions to
  /// [AuthState.pinLockedOut] without invoking Argon2id at all.
  Future<Failure?> activateProfile(String userId, {required String pin}) async {
    try {
      final profile = await ref
          .read(localProfileRepositoryProvider)
          .profileById(userId);
      if (profile == null) {
        return const Failure.validation(message: 'Profile no longer exists.');
      }

      if (_isLockedOut(profile)) {
        state = AuthState.pinLockedOut(profile, profile.pinLockedUntil!);
        return const Failure.auth(
          message: 'Too many failed attempts. Re-verify via OTP to reset.',
        );
      }

      final pinValid =
          await ref.read(pinServiceProvider).verifyPin(pin, profile.pinHash);
      if (!pinValid) {
        await _handleFailedPinAttempt(profile);
        return const Failure.auth(message: 'Incorrect PIN.');
      }

      await ref.read(localProfileRepositoryProvider).resetPinAttempts(userId);
      await ref.read(localProfileRepositoryProvider).activate(userId);
      state = AuthState.sessionActive(profile, locked: false);
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  // ── Lock / unlock ───────────────────────────────────────────────
  /// Re-locks the active session after the background inactivity timeout.
  void lock() {
    final current = state;
    if (current is SessionActive && !current.locked) {
      state = AuthState.sessionActive(current.profile, locked: true);
    }
  }

  /// Unlocks the active session with the profile's [pin].
  ///
  /// The profile is re-read from storage on every attempt so the attempt
  /// counter and lockout flag always reflect the persisted state.
  Future<Failure?> unlock({required String pin}) async {
    final current = state;
    if (current is! SessionActive) {
      return const Failure.auth(message: 'No active session to unlock.');
    }

    final profile = await ref
        .read(localProfileRepositoryProvider)
        .profileById(current.profile.userId);
    if (profile == null) {
      return const Failure.validation(message: 'Profile no longer exists.');
    }

    if (_isLockedOut(profile)) {
      state = AuthState.pinLockedOut(profile, profile.pinLockedUntil!);
      return const Failure.auth(
        message: 'Too many failed attempts. Re-verify via OTP to reset.',
      );
    }

    try {
      final pinValid =
          await ref.read(pinServiceProvider).verifyPin(pin, profile.pinHash);
      if (!pinValid) {
        await _handleFailedPinAttempt(profile);
        return const Failure.auth(message: 'Incorrect PIN.');
      }

      await ref.read(localProfileRepositoryProvider).resetPinAttempts(profile.userId);
      state = AuthState.sessionActive(profile, locked: false);
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  // ── Lockout resolution via OTP re-verification ──────────────────
  /// Starts OTP re-verification for a locked-out profile.
  ///
  /// Reuses the standard OTP request/verify endpoints but remembers the
  /// [userId] so a successful verification routes to the set-new-PIN flow
  /// for the SAME profile (it is never treated as a fresh registration).
  Future<Failure?> startLockoutResolution(String userId) async {
    try {
      final profile = await ref
          .read(localProfileRepositoryProvider)
          .profileById(userId);
      if (profile == null) {
        return const Failure.validation(message: 'Profile no longer exists.');
      }

      await ref.read(identityApiProvider).requestOtp(profile.phone);
      _pendingLockoutUserId = userId;
      state = AuthState.otpPending(profile.phone);
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  /// Completes lockout resolution after OTP verification.
  ///
  /// Clears `pin_attempt_count` and `pin_locked_until` for the profile and
  /// routes to [AuthState.settingPin] so the user sets a NEW PIN — the old
  /// PIN is never silently kept.
  Future<Failure?> completeLockoutResolution(String phone, String code) async {
    try {
      final userId = _pendingLockoutUserId;
      if (userId == null) {
        return const Failure.validation(
          message: 'No lockout resolution in progress.',
        );
      }

      final result = await ref.read(identityApiProvider).verifyOtp(phone, code);
      if (result.userId != userId) {
        return const Failure.auth(message: 'OTP verified for a different user.');
      }

      ref.read(tokenStoreProvider).accessToken = result.accessToken;
      await ref.read(localProfileRepositoryProvider).clearLockout(userId);
      _pendingLockoutUserId = null;
      state = AuthState.settingPin(
        phone: phone,
        userId: result.userId,
        refreshToken: result.refreshToken,
      );
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  // ── Shift end / device management ───────────────────────────────
  /// Ends the current shift but keeps the profile (and its PIN) on the
  /// device for the next shift — no OTP needed next time.
  Future<void> endShift() async {
    ref.read(tokenStoreProvider).accessToken = null;
    await ref.read(localProfileRepositoryProvider).endShift();

    final profiles =
        await ref.read(localProfileRepositoryProvider).listProfiles();
    if (profiles.isNotEmpty) {
      state = AuthState.profilesAvailable(profiles);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Returns to the OTP sign-in screen so a NEW user (or an existing user
  /// on another number) can start the phone-first onboarding.
  ///
  /// Profiles already on the device are kept — they reappear on the picker
  /// after the next cold start (or via [endShift]).
  void startOtpLogin() {
    ref.read(tokenStoreProvider).accessToken = null;
    state = const AuthState.unauthenticated();
  }

  /// Permanently removes the **currently active** profile from the device
  /// (profile row and refresh token).
  ///
  /// This is a destructive, re-authenticated operation and is never passed
  /// an arbitrary [userId] from the caller — the removal target is always
  /// the profile held by [AuthState.sessionActive]. Before anything is
  /// deleted the caller must supply [pin], which is freshly verified
  /// against that profile's Argon2id hash (the same re-authentication
  /// requirement as the lockout-resolution flow). The method refuses to
  /// run unless a session is currently active.
  ///
  /// Returns `null` on success and a [Failure] otherwise (no active
  /// session, correct-target mismatch, or incorrect PIN).
  Future<Failure?> removeFromDevice({required String pin}) async {
    final current = state;
    if (current is! SessionActive) {
      return const Failure.auth(
        message: 'No active session to remove from this device.',
      );
    }

    final activeId = current.profile.userId;
    final profile = await ref
        .read(localProfileRepositoryProvider)
        .profileById(activeId);
    if (profile == null) {
      return const Failure.validation(message: 'Profile no longer exists.');
    }

    try {
      final pinValid =
          await ref.read(pinServiceProvider).verifyPin(pin, profile.pinHash);
      if (!pinValid) {
        await _handleFailedPinAttempt(profile);
        return const Failure.auth(message: 'Incorrect PIN.');
      }
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }

    ref.read(tokenStoreProvider).accessToken = null;
    await ref.read(localProfileRepositoryProvider).removeProfile(activeId);
    await ref.read(secureStorageServiceProvider).deleteRefreshToken(activeId);

    final profiles =
        await ref.read(localProfileRepositoryProvider).listProfiles();
    if (profiles.isNotEmpty) {
      state = AuthState.profilesAvailable(profiles);
    } else {
      state = const AuthState.unauthenticated();
    }
    return null;
  }

  // ── Lockout internals ───────────────────────────────────────────
  String? _pendingLockoutUserId;

  bool _isLockedOut(LocalUserProfile profile) {
    final lockedUntil = profile.pinLockedUntil;
    return lockedUntil != null && lockedUntil.isAfter(DateTime.now());
  }

  Future<void> _handleFailedPinAttempt(LocalUserProfile profile) async {
    final newCount = profile.pinAttemptCount + 1;
    await ref
        .read(localProfileRepositoryProvider)
        .incrementPinAttempts(profile.userId, newCount);

    if (newCount >= AppDurations.maxPinAttempts) {
      final lockedUntil =
          DateTime.now().add(AppDurations.pinLockoutIndefinite);
      await ref.read(localProfileRepositoryProvider).lockProfile(
            profile.userId,
            lockedUntil: lockedUntil,
          );
      state = AuthState.pinLockedOut(
        profile.copyWith(
          pinAttemptCount: newCount,
          pinLockedUntil: Value(lockedUntil),
        ),
        lockedUntil,
      );
    }
  }
}
