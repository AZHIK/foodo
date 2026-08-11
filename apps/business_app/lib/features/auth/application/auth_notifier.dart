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
  ///
  /// For an active (unlocked) profile the server is consulted again before
  /// declaring a session ready: the access token is in-memory only and the
  /// refresh token (rotating) is exchanged to restore one, then
  /// `onboarding-status` is re-checked. This is what makes onboarding
  /// resumable — a self-registered owner who was killed mid-onboarding
  /// returns to [AuthState.onboardingRequired] and is routed back to the
  /// onboarding flow, rather than landing in an ambiguous ready state
  /// based on a stale local flag.
  Future<void> initialize() async {
    final profiles =
        await ref.read(localProfileRepositoryProvider).listProfiles();

    final active = profiles.where((p) => p.isCurrentlyActive).firstOrNull;
    if (active != null) {
      if (_isLockedOut(active)) {
        state = AuthState.pinLockedOut(active, active.pinLockedUntil!);
      } else {
        state = await _resolveBootSession(active);
      }
    } else if (profiles.isNotEmpty) {
      state = AuthState.profilesAvailable(profiles);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Restores a session for [active] and re-checks onboarding status.
  ///
  /// If the refresh token can be exchanged and the status query succeeds,
  /// returns either [AuthState.onboardingRequired] (owner still needs a
  /// business) or a locked [AuthState.sessionActive] (has a role).
  ///
  /// If the session cannot be restored or the status query fails (offline,
  /// revoked token), it falls back to today's behaviour — the profile
  /// stays active but the app boots locked so the user unlocks with their
  /// PIN. Invited staff who work offline are therefore never blocked,
  /// while the owner path always prefers the live server check whenever it
  /// is reachable.
  Future<AuthState> _resolveBootSession(LocalUserProfile active) async {
    final refreshToken =
        await ref.read(secureStorageServiceProvider).readRefreshToken(
              active.userId,
            );
    if (refreshToken == null) {
      return AuthState.sessionActive(active, locked: true);
    }

    try {
      final result =
          await ref.read(identityApiProvider).refreshAccessToken(refreshToken);
      ref.read(tokenStoreProvider).accessToken = result.accessToken;
      // Refresh tokens rotate server-side on every exchange; persist the
      // rotated token so the next boot can restore the session too.
      await ref
          .read(secureStorageServiceProvider)
          .saveRefreshToken(userId: active.userId, token: result.refreshToken);

      final onboardingStatus =
          await ref.read(identityApiProvider).fetchOnboardingStatus();
      final incomingBusinessId = onboardingStatus.businessId;

      // Check device lock consistency
      final deviceConfig =
          await ref.read(localProfileRepositoryProvider).getDeviceConfig();
      if (deviceConfig != null &&
          deviceConfig.lockedBusinessId != null &&
          incomingBusinessId != null &&
          incomingBusinessId != deviceConfig.lockedBusinessId) {
        // Device lock exists but this profile belongs to a different business.
        // This shouldn't happen with proper locking, but if it does, fall back
        // to locked session so user can unlock and see the error. Don't leave
        // an unscoped token behind — it would 403 on the first scoped call.
        ref.read(tokenStoreProvider).accessToken = null;
        return AuthState.sessionActive(active, locked: true);
      }

      if (onboardingStatus.needsOnboarding) {
        return AuthState.onboardingRequired(active);
      }

      // The user has a business. The refresh endpoint only ever issues an
      // unscoped token, so scope it now or every business-scoped call would
      // 403. (business_id is guaranteed non-null when needs_onboarding is
      // false; a null here is a server anomaly we defensively survive.)
      if (incomingBusinessId != null) {
        await _switchToBusinessContext(
          businessId: incomingBusinessId,
          userId: active.userId,
        );
      }

      return AuthState.sessionActive(active, locked: true);
    } catch (_) {
      // Offline / token failure. The profile stays active so staff can still
      // unlock with their PIN, but the access token cannot be trusted: clear
      // it so the app never silently resumes with a stale/unscoped token that
      // would 403 on the first business-scoped call.
      ref.read(tokenStoreProvider).accessToken = null;
      return AuthState.sessionActive(active, locked: true);
    }
  }

  /// Scopes the current session to [businessId] and persists the result.
  ///
  /// The OTP-verify and refresh endpoints only ever issue unscoped tokens
  /// (`active_business_id=None`, empty roles/permissions), so before a
  /// session can make any business-scoped call it must exchange the
  /// unscoped token for a scoped one via `POST /auth/context/switch`.
  ///
  /// On success the scoped access token replaces the unscoped one in
  /// [TokenStore] and the rotated refresh token is persisted (keyed by
  /// [userId]), exactly as the refresh path already does.
  ///
  /// Throws [Failure] on error — callers decide whether to retry.
  Future<void> _switchToBusinessContext({
    required String businessId,
    required String userId,
  }) async {
    final result =
        await ref.read(identityApiProvider).switchBusinessContext(businessId);
    ref.read(tokenStoreProvider).accessToken = result.accessToken;
    await ref
        .read(secureStorageServiceProvider)
        .saveRefreshToken(userId: userId, token: result.refreshToken);
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
  ///
  /// The resulting state depends on the server-side onboarding status
  /// (`GET /users/me/onboarding-status`), which is the source of truth for
  /// whether this user has a business yet:
  ///
  /// - `needs_onboarding=true` (self-registered owner, no roles yet) →
  ///   [AuthState.onboardingRequired] — authenticated but not fully set up.
  /// - `needs_onboarding=false` (invited staff, role assigned at invite
  ///   time) → [AuthState.sessionActive], exactly as before.
  ///
  /// Device-level business locking: the first profile added to a device
  /// locks that device to one business. Subsequent profiles must belong
  /// to the same business or are rejected.
  Future<Failure?> setPin({
    required String phone,
    required String userId,
    required String refreshToken,
    required String pin,
    String? displayName,
  }) async {
    try {
      // Check device lock before proceeding
      final deviceConfig =
          await ref.read(localProfileRepositoryProvider).getDeviceConfig();
      final onboardingStatus =
          await ref.read(identityApiProvider).fetchOnboardingStatus();
      final incomingBusinessId = onboardingStatus.businessId;

      if (deviceConfig != null && deviceConfig.lockedBusinessId != null) {
        if (incomingBusinessId != deviceConfig.lockedBusinessId) {
          return Failure.auth(
            message:
                'This device belongs to ${deviceConfig.lockedBusinessName} — contact your admin',
          );
        }
      }

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

      final activeProfile =
          await ref.read(localProfileRepositoryProvider).activeProfile();

      if (onboardingStatus.needsOnboarding) {
        // Self-registered owner — no business yet, route to onboarding.
        state = AuthState.onboardingRequired(activeProfile);
        return null;
      }

      // Invited staff — a business already exists. Set the device lock if
      // not set yet, then obtain a business-scoped token before starting the
      // session so the first business-scoped call doesn't 403.
      if (deviceConfig == null || deviceConfig.lockedBusinessId == null) {
        if (incomingBusinessId != null) {
          await ref.read(localProfileRepositoryProvider).setDeviceLock(
                businessId: incomingBusinessId,
                businessName:
                    onboardingStatus.businessName ?? 'Unknown Business',
              );
        }
      }

      if (incomingBusinessId == null) {
        return const Failure.auth(
          message:
              'Could not scope this session to a business. Please try again.',
        );
      }

       await _switchToBusinessContext(
        businessId: incomingBusinessId,
        userId: userId,
      );

      state = AuthState.sessionActive(activeProfile, locked: false);
      return null;
    } on Failure catch (failure) {
      // If we had already stored an unscoped token (from verifyOtp or
      // refresh), clear it so the user doesn't silently proceed with a
      // token that would 403 on the first business-scoped call.
      ref.read(tokenStoreProvider).accessToken = null;
      return failure;
    } catch (error) {
      return Failure.unknown(error: error);
    }
  }

  /// Promotes an authenticated-but-not-yet-set-up profile to a fully ready
  /// session.
  ///
  /// Called once business creation succeeds — at that point the server has
  /// assigned the caller a business role, so `sessionActive` is now the
  /// correct terminal state. This is what makes onboarding resumable: if
  /// the app is killed *before* this runs, the boot path re-checks
  /// onboarding-status on the next launch and routes back to the
  /// onboarding flow rather than trusting a locally cached flag.
  ///
  /// Also sets the device lock if not already set (first profile on device
  /// for a self-registering owner), and swaps the unscoped OTP token for a
  /// business-scoped one (`POST /auth/context/switch`) before declaring the
  /// session active — without a scoped token the first business-scoped call
  /// would 403.
  ///
  /// Returns `null` on success and a [Failure] on error. On failure the
  /// state stays [AuthState.onboardingRequired], so the caller can retry
  /// just the scoping step (not re-create the business).
  Future<Failure?> completeOnboarding() async {
    final current = state;
    if (current is! OnboardingRequired) return null;

    final OnboardingStatusResult onboardingStatus;
    try {
      onboardingStatus =
          await ref.read(identityApiProvider).fetchOnboardingStatus();
    } on Failure catch (failure) {
      return failure;
    }

    final businessId = onboardingStatus.businessId;
    if (onboardingStatus.needsOnboarding || businessId == null) {
      return const Failure.validation(
        message: 'Business creation has not completed. Please try again.',
      );
    }

    // Set the device lock if not already set (first profile on device for a
    // self-registering owner).
    final deviceConfig =
        await ref.read(localProfileRepositoryProvider).getDeviceConfig();
    if (deviceConfig == null || deviceConfig.lockedBusinessId == null) {
      await ref.read(localProfileRepositoryProvider).setDeviceLock(
            businessId: businessId,
            businessName: onboardingStatus.businessName ?? 'Unknown Business',
          );
    }

    // Obtain a business-scoped access token. The OTP-issued token is
    // unscoped and the first business-scoped call would otherwise 403.
    try {
      await _switchToBusinessContext(
        businessId: businessId,
        userId: current.profile.userId,
      );
    } on Failure catch (_) {
      // Clear the unscoped token so a retry doesn't silently use it.
      ref.read(tokenStoreProvider).accessToken = null;
       return const Failure.auth(
         message: 'Business set up, but the session could not be scoped to it. '
             'Check your connection and retry.',
      );
    }

    state = AuthState.sessionActive(current.profile, locked: false);
    return null;
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
  ///
  /// If this was the last profile on the device, the device lock is also
  /// cleared so the device can be onboarded for a different business next.
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
      // Last profile removed — clear device lock so device can be
      // onboarded for a different business next.
      await ref.read(localProfileRepositoryProvider).clearDeviceLock();
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
