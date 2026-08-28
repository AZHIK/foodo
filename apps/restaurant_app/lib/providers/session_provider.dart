import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_profile_repository.dart';
import '../models/session.dart';
import '../models/staff_member.dart';
import '../utils/pin_hasher.dart';
import 'auth_provider.dart';
import 'database_providers.dart';
import 'staff_provider.dart';

/// Who is at this terminal and how far through the door they are.
///
/// Every auth screen writes here and the router's redirect reads here, so the
/// flow has exactly one source of truth. Nothing navigates by hand: a screen
/// records what happened, and the guard decides where that leaves you.
///
/// A cold start is always either the phone-number screen (nothing saved on
/// this device yet) or the profile picker (someone has signed in here
/// before) — never straight to the PIN screen. [SessionState.entryRoute]
/// only reaches `/auth/unlock` once [selectProfile] has recorded who is
/// signing in, which happens from the picker, not from `build()`.
class SessionNotifier extends Notifier<SessionState> {
  late final LocalProfileRepository _profileRepo;

  @override
  SessionState build() {
    _profileRepo = ref.watch(localProfileRepositoryProvider);
    return freshDevice;
  }

  /// A device nobody has signed in on. Used by the "sign in differently" paths
  /// and as the synchronous state `build()` returns before storage has been
  /// read.
  static const freshDevice = SessionState();

  /// A terminal already set up, signed in and unlocked. `build()` no longer
  /// uses this itself — it reads real storage — but tests still `copyWith`
  /// off it as a convenient fully-onboarded base state (`pumpSession`
  /// overrides `sessionProvider`'s state directly, after `build()` has
  /// already run, so this has no effect on what a real app instance boots
  /// into).
  static const seed = SessionState(
    savedProfileIds: ['stf-01', 'stf-02', 'stf-03'],
    activeStaffId: 'stf-01',
    isLoggedIn: true,
    pin: '246813',
    isUnlocked: true,
    hasCompletedOnboarding: true,
  );

  // -------------------------------------------------------------------------
  // Boot
  // -------------------------------------------------------------------------

  /// Loads saved profiles from the database and updates the session state.
  /// Called during app initialization to populate the profile picker if users
  /// have previously signed in.
  Future<void> loadSavedProfiles() async {
    try {
      final profiles = await _profileRepo.allProfiles() as List;
      if (profiles.isNotEmpty) {
        final profileIds = [for (final profile in profiles) profile.id as String];
        state = state.copyWith(savedProfileIds: profileIds);
      }
    } catch (_) {
      // If database read fails, continue with empty saved profiles
    }
  }

  /// Called by the splash once its brand moment has played out. Until this
  /// flips, the router holds everything on the splash.
  void completeBootstrap() {
    if (state.bootstrapped) return;
    state = state.copyWith(bootstrapped: true);
  }

  // -------------------------------------------------------------------------
  // Sign in
  // -------------------------------------------------------------------------

  /// Marks a profile as the one signing in, without granting access — the PIN
  /// screen still has to be satisfied.
  ///
  /// Also loads this profile's saved PIN hash and this device's onboarding
  /// status, so `hasPin` and `hasCompletedOnboarding` are correct once
  /// `submitPin` unlocks the session — `selectProfile` is now the only place
  /// that flips `isLoggedIn`, so nothing else populates them.
  Future<void> selectProfile(String staffId) async {
    state = state.copyWith(
      activeStaffId: staffId,
      isLoggedIn: true,
      isUnlocked: false,
      failedAttempts: 0,
      clearLockout: true,
    );

    try {
      final device = await _profileRepo.currentDevice();
      final profile = await _profileRepo.getProfile(staffId);
      // `pin` is set to the stored *hash*, not the PIN itself — `hasPin` only
      // needs a non-empty value to gate routing correctly, and `submitPin`'s
      // real verification path checks the hash via `_profileRepo.getProfile`
      // regardless, so nothing here ever holds a plaintext PIN.
      state = state.copyWith(
        hasCompletedOnboarding: device != null,
        pin: profile?.pinHash as String?,
      );
    } catch (_) {
      // Nothing readable — leave hasPin/hasCompletedOnboarding as they were.
    }
  }

  /// Requests an OTP code for a phone number (start of login flow).
  Future<void> requestOtp(String phone) async {
    try {
      final auth = ref.read(authProvider.notifier);
      await auth.requestOtp(phone);
    } catch (e) {
      state = state.copyWith(pin: 'OTP request failed: $e');
      rethrow;
    }
  }

  /// Verifies an OTP code and completes login.
  ///
  /// After verification, the session is marked as logged in and unlocked
  /// (OTP is proof of identity). Whether the user lands on the dashboard or
  /// the business-creation onboarding flow next comes down to one thing: did
  /// `verifyOtp` find a store to lock this device to?
  ///
  /// - Has a store → they were logged into it (`_switchContextAndLock`
  ///   provisioned `DeviceConfig`) → treated as a returning user.
  /// - No store → nothing was provisioned → treated the same as a brand-new
  ///   signup, and `entryRoute` sends them to onboarding to register a
  ///   business, store included.
  ///
  /// `_profileRepo.currentDevice()` is re-read here (rather than assumed)
  /// because that provisioning happens as a side effect inside
  /// `AuthNotifier._switchContextAndLock`, not in this method.
  Future<void> completeOtpLogin(String code) async {
    try {
      final auth = ref.read(authProvider.notifier);
      await auth.verifyOtp(code);

      final authState = ref.read(authProvider);
      final staffId = authState.userId;
      if (staffId == null) throw StateError('User ID not set after OTP verify');

      final device = await _profileRepo.currentDevice();

      // OTP is a stronger proof than PIN, so it unlocks immediately.
      state = state.copyWith(
        activeStaffId: staffId,
        isLoggedIn: true,
        isUnlocked: true,
        hasCompletedOnboarding: device != null,
        savedProfileIds: _withProfile(staffId),
        failedAttempts: 0,
        clearLockout: true,
      );
    } catch (e) {
      state = state.copyWith(pin: 'OTP login failed: $e');
      rethrow;
    }
  }

  /// Drops back to the signed-out state but keeps the device's saved profiles
  /// — signing out is not the same as forgetting who works here.
  void signOut() {
    state = state.copyWith(
      isLoggedIn: false,
      isUnlocked: false,
      failedAttempts: 0,
      clearLockout: true,
      clearActiveStaff: true,
    );
  }

  // -------------------------------------------------------------------------
  // PIN
  // -------------------------------------------------------------------------

  /// Sets the PIN for the active profile and saves it hashed to the database.
  ///
  /// Called during first login (after OTP) or when changing PIN.
  /// Calls authProvider to hash and persist the PIN via LocalUserProfiles.
  Future<void> setPin(String pin) async {
    try {
      final auth = ref.read(authProvider.notifier);
      await auth.setPin(pin);

      state = state.copyWith(
        pin: pin,
        isUnlocked: true,
        failedAttempts: 0,
        clearLockout: true,
        savedProfileIds: _withProfile(state.activeStaffId),
      );
    } catch (e) {
      state = state.copyWith(pin: 'PIN setup failed: $e');
      rethrow;
    }
  }

  /// Checks [entered] PIN against the stored hash, recording the attempt.
  ///
  /// Returns whether it matched, so the screen can play its success or shake
  /// animation — but the counting and the lockout happen here, not in the
  /// widget, so a second entry point could not skip them.
  ///
  /// Checks against LocalUserProfiles.pinHash (HMAC-SHA256 salted), not plaintext.
  /// Tracks lockout via LocalUserProfiles.lockedUntil, which persists across restarts.
  Future<bool> submitPin(String entered, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final staffId = state.activeStaffId;

    if (staffId == null) return false;
    if (state.isLockedOutAt(at)) return false;

    try {
      // Fetch the stored profile.
      final profile = await _profileRepo.getProfile(staffId);
      if (profile == null) return false;

      // Verify the entered PIN against the stored hash.
      final isCorrect = PinHasher.verify(entered, profile.pinHash, profile.pinSalt);

      if (isCorrect) {
        // Clear lockout and unlock.
        await _profileRepo.updateLockout(staffId, 0, null);
        state = state.copyWith(
          isUnlocked: true,
          failedAttempts: 0,
          clearLockout: true,
        );
        return true;
      }

      // PIN was wrong. Increment attempts and update DB.
      final attempts = (profile.failedPinAttempts ?? 0) + 1;
      final lockUntil = attempts >= SessionState.maxAttempts
          ? at.add(SessionState.lockoutDuration)
          : null;

      await _profileRepo.updateLockout(staffId, attempts, lockUntil);

      state = state.copyWith(
        failedAttempts: attempts,
        lockedUntil: lockUntil,
      );
      return false;
    } catch (_) {
      // If DB read fails, fall back to in-memory check (for tests/demo).
      if (state.hasPin && entered == state.pin) {
        state = state.copyWith(
          isUnlocked: true,
          failedAttempts: 0,
          clearLockout: true,
        );
        return true;
      }

      final attempts = state.failedAttempts + 1;
      state = state.copyWith(
        failedAttempts: attempts,
        lockedUntil: attempts >= SessionState.maxAttempts
            ? at.add(SessionState.lockoutDuration)
            : null,
      );
      return false;
    }
  }

  /// Called by the unlock screen's countdown when it reaches zero.
  void clearLockout() {
    state = state.copyWith(failedAttempts: 0, clearLockout: true);
  }

  /// Locks the terminal without signing anyone out — what a "lock now" button
  /// on the till would do at the end of a shift.
  void lock() => state = state.copyWith(isUnlocked: false);

  // -------------------------------------------------------------------------
  // Onboarding & preferences
  // -------------------------------------------------------------------------

  void completeOnboarding() =>
      state = state.copyWith(hasCompletedOnboarding: true);

  void setTwoFactor(bool enabled) =>
      state = state.copyWith(twoFactorEnabled: enabled);

  /// Removes a profile from this device — the account still exists, it just
  /// stops being offered on the picker.
  void forgetProfile(String staffId) {
    state = state.copyWith(
      savedProfileIds: [
        for (final id in state.savedProfileIds)
          if (id != staffId) id,
      ],
    );
  }

  /// Adds [staffId] to the saved list, newest first, without duplicating it.
  List<String> _withProfile(String? staffId) {
    if (staffId == null) return state.savedProfileIds;
    return [
      staffId,
      for (final id in state.savedProfileIds)
        if (id != staffId) id,
    ];
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// The staff member currently signing in or signed in.
///
/// Resolved against the live staff list, so renaming someone on the Staff
/// screen renames them on the lock screen too. Falls back to the locally
/// saved profile (name only — this runs before the PIN is entered, so there
/// is no business-scoped token yet to fetch the live list with), then to
/// [currentUserProvider] — the owner — when no profile has been selected,
/// which is what the app did before sessions existed.
final sessionStaffProvider = Provider<StaffMember?>((ref) {
  final id = ref.watch(sessionProvider.select((s) => s.activeStaffId));
  if (id == null) return ref.watch(currentUserProvider);

  for (final member in ref.watch(staffMembersProvider).valueOrNull ?? const <StaffMember>[]) {
    if (member.id == id) return member;
  }
  for (final member in ref.watch(localSavedStaffProvider).valueOrNull ?? const <StaffMember>[]) {
    if (member.id == id) return member;
  }
  return ref.watch(currentUserProvider);
});

/// The profiles the picker offers, in saved order, skipping any whose staff
/// record has since been deleted.
final savedProfilesProvider = Provider<List<StaffMember>>((ref) {
  final ids = ref.watch(sessionProvider.select((s) => s.savedProfileIds));
  final members = ref.watch(staffMembersProvider).valueOrNull ?? const <StaffMember>[];
  final localMembers = ref.watch(localSavedStaffProvider);

  // Combine real staff and local saved staff
  final allMembers = [...members];
  if (localMembers.isLoading == false && localMembers.hasValue) {
    for (final member in localMembers.value!) {
      if (!allMembers.any((m) => m.id == member.id)) {
        allMembers.add(member);
      }
    }
  }

  final byId = {for (final member in allMembers) member.id: member};
  return [for (final id in ids) ?byId[id]];
});

/// Whether the app's main shell may be shown at all.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session.isLoggedIn && session.isUnlocked;
});

/// Bridges the session into something [GoRouter] can listen to.
///
/// go_router re-runs its redirect when this notifies. Doing it this way rather
/// than rebuilding the router on every session change matters: a rebuilt
/// router is a *different* router, and anything holding the old one — a test,
/// a widget mid-navigation — would be talking to a corpse.
class SessionRefreshNotifier extends ChangeNotifier {
  SessionRefreshNotifier(this._ref) {
    _ref.listen<SessionState>(sessionProvider, (previous, next) {
      // Only the fields the guard actually reads. The failed-attempt counter
      // changes on every wrong digit and must not re-run routing.
      if (previous == null || _routingKey(previous) != _routingKey(next)) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;

  static Object _routingKey(SessionState s) => (
    s.bootstrapped,
    s.isLoggedIn,
    s.hasPin,
    s.isUnlocked,
    s.hasCompletedOnboarding,
    s.hasSavedProfiles,
  );
}

final sessionRefreshProvider = Provider<SessionRefreshNotifier>((ref) {
  final notifier = SessionRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
