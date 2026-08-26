import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../models/staff_member.dart';
import 'staff_provider.dart';

/// Which state the app boots into.
///
/// Once onboarding is done the auth flow is unreachable from a running app —
/// the guard sends you straight past it — so this is how the screens get shown
/// at all. It exists because this build is a UI mock whose auth screens are
/// part of what is being reviewed; a real build reads the equivalent off
/// storage and this enum goes away with it.
enum DemoBoot {
  /// A terminal already set up and unlocked. Opens on the Dashboard.
  readyToTrade,

  /// A device nobody has signed in on. Opens on phone entry and walks the
  /// whole flow — OTP, set PIN, onboarding.
  freshDevice,

  /// Set up, signed in, but locked. Opens on the PIN pad.
  lockedTerminal,
}

/// Flip this to walk the auth flow. See [DemoBoot].
const kDemoBoot = DemoBoot.readyToTrade;

/// Who is at this terminal and how far through the door they are.
///
/// Every auth screen writes here and the router's redirect reads here, so the
/// flow has exactly one source of truth. Nothing navigates by hand: a screen
/// records what happened, and the guard decides where that leaves you.
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => switch (kDemoBoot) {
    DemoBoot.readyToTrade => seed,
    DemoBoot.freshDevice => freshDevice,
    DemoBoot.lockedTerminal => seed.copyWith(isUnlocked: false),
  };

  /// The state this build boots into: a terminal that has been set up, has
  /// signed-in profiles, and is already unlocked for this session.
  ///
  /// A locked terminal would be the more realistic cold start, but it would
  /// also put a PIN pad in front of every existing screen and every existing
  /// test on launch. Shipping "already unlocked" keeps the app openable while
  /// leaving the whole auth flow reachable — set [kDemoBoot] to
  /// [DemoBoot.freshDevice] or [DemoBoot.lockedTerminal] to walk it.
  static const seed = SessionState(
    savedProfileIds: ['stf-01', 'stf-02', 'stf-03'],
    activeStaffId: 'stf-01',
    isLoggedIn: true,
    pin: '246813',
    isUnlocked: true,
    hasCompletedOnboarding: true,
  );

  /// A device nobody has signed in on. Used by the "sign in differently" paths
  /// and useful for driving the first-run flow by hand.
  static const freshDevice = SessionState();

  // -------------------------------------------------------------------------
  // Boot
  // -------------------------------------------------------------------------

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
  void selectProfile(String staffId) {
    state = state.copyWith(
      activeStaffId: staffId,
      isLoggedIn: true,
      isUnlocked: false,
      failedAttempts: 0,
      clearLockout: true,
    );
  }

  /// Completes an OTP sign-in.
  ///
  /// [staffId] is who the phone number resolved to. There is no directory
  /// behind that lookup yet, so the caller supplies it.
  void completeOtpLogin(String staffId) {
    state = state.copyWith(
      activeStaffId: staffId,
      isLoggedIn: true,
      // OTP is a stronger proof than the PIN it replaces, so it unlocks too.
      isUnlocked: true,
      savedProfileIds: _withProfile(staffId),
      failedAttempts: 0,
      clearLockout: true,
    );
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

  void setPin(String pin) {
    state = state.copyWith(
      pin: pin,
      isUnlocked: true,
      failedAttempts: 0,
      clearLockout: true,
      savedProfileIds: _withProfile(state.activeStaffId),
    );
  }

  /// Checks [entered] against the stored PIN, recording the attempt either way.
  ///
  /// Returns whether it matched, so the screen can play its success or shake
  /// animation — but the counting and the lockout happen here, not in the
  /// widget, so a second entry point could not skip them.
  bool submitPin(String entered, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (state.isLockedOutAt(at)) return false;

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
/// screen renames them on the lock screen too. Falls back to
/// [currentUserProvider] — the owner — when no profile has been selected,
/// which is what the app did before sessions existed.
final sessionStaffProvider = Provider<StaffMember?>((ref) {
  final id = ref.watch(sessionProvider.select((s) => s.activeStaffId));
  if (id == null) return ref.watch(currentUserProvider);

  for (final member in ref.watch(staffMembersProvider)) {
    if (member.id == id) return member;
  }
  return ref.watch(currentUserProvider);
});

/// The profiles the picker offers, in saved order, skipping any whose staff
/// record has since been deleted.
final savedProfilesProvider = Provider<List<StaffMember>>((ref) {
  final ids = ref.watch(sessionProvider.select((s) => s.savedProfileIds));
  final members = ref.watch(staffMembersProvider);

  final byId = {for (final member in members) member.id: member};
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
