import 'package:flutter/foundation.dart';

/// Where the person at this terminal stands with the app.
///
/// One object rather than a scatter of booleans in different providers,
/// because the router has to read all of them together to decide where a
/// request may go — and a redirect that reads four providers is four chances
/// to see a half-updated session.
///
/// Everything here is in memory. Persisting it later means overriding
/// [sessionProvider] with a notifier backed by secure storage; no screen and
/// no route guard has to change.
@immutable
class SessionState {
  const SessionState({
    this.savedProfileIds = const [],
    this.activeStaffId,
    this.isLoggedIn = false,
    this.pin,
    this.isUnlocked = false,
    this.hasCompletedOnboarding = false,
    this.twoFactorEnabled = false,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.bootstrapped = false,
  });

  /// Staff who have signed in on this device before, newest first. What makes
  /// the Profile Picker worth showing at all — an empty list means this is a
  /// fresh terminal and the only way in is OTP.
  final List<String> savedProfileIds;

  /// Who is signing in, or signed in. Set by the Profile Picker before the PIN
  /// is entered, so the unlock screen can greet them by name.
  final String? activeStaffId;

  /// Whether an OTP has been completed for [activeStaffId].
  final bool isLoggedIn;

  /// The unlock PIN, once set. Null means Set PIN has not been through yet.
  ///
  /// Stored in the clear because there is nothing behind it — a real build
  /// hashes this and never holds the plaintext, which is a change to this
  /// field and [SessionNotifier.setPin] alone.
  final String? pin;

  /// Whether the PIN has been entered *this session*. Distinct from
  /// [isLoggedIn]: a terminal left on the counter overnight is still logged in
  /// and very much not unlocked.
  final bool isUnlocked;

  final bool hasCompletedOnboarding;

  /// Ask for an OTP as well as a PIN. UI-only for now.
  final bool twoFactorEnabled;

  /// Consecutive wrong PINs. Reset on success and when a lockout expires.
  final int failedAttempts;

  /// When the current lockout ends, or null when not locked out.
  final DateTime? lockedUntil;

  /// Set once the splash has had its moment. The router will not redirect off
  /// the splash before this flips, which is what keeps the brand moment from
  /// being a single frame nobody sees.
  final bool bootstrapped;

  /// How many wrong PINs are allowed before the terminal locks itself.
  static const maxAttempts = 3;

  /// How long a lockout lasts. Long enough to stop someone guessing, short
  /// enough that a cashier who fat-fingered three times is not stranded
  /// mid-service.
  static const lockoutDuration = Duration(seconds: 30);

  bool get hasPin => pin != null && pin!.isNotEmpty;

  bool get hasSavedProfiles => savedProfileIds.isNotEmpty;

  /// True while a lockout is still running. Computed rather than stored so it
  /// cannot go stale between the timer's ticks.
  bool isLockedOutAt(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  /// Seconds left on the lockout, floored at zero.
  int lockoutSecondsLeft(DateTime now) {
    final until = lockedUntil;
    if (until == null) return 0;
    final left = until.difference(now).inMilliseconds;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  /// The one place that decides where a signed-out-or-locked person belongs.
  ///
  /// Returning a route from the state itself keeps the router's redirect a
  /// lookup rather than a second copy of these rules — and makes the whole
  /// decision testable without pumping a widget.
  String get entryRoute {
    if (!isLoggedIn) {
      return hasSavedProfiles ? _profilesPath : _loginPath;
    }
    if (!hasPin) return _setPinPath;
    if (!isUnlocked) return _unlockPath;
    if (!hasCompletedOnboarding) return _onboardingPath;
    return _dashboardPath;
  }

  // Path literals rather than an import of AppRoute: the router imports this
  // model, and having the model import the router back would be a cycle.
  // AppRoute asserts these agree with it, so a rename cannot drift.
  static const _profilesPath = '/auth/profiles';
  static const _loginPath = '/auth/login';
  static const _setPinPath = '/auth/set-pin';
  static const _unlockPath = '/auth/unlock';
  static const _onboardingPath = '/auth/onboarding';
  static const _dashboardPath = '/dashboard';

  SessionState copyWith({
    List<String>? savedProfileIds,
    String? activeStaffId,
    bool? isLoggedIn,
    String? pin,
    bool? isUnlocked,
    bool? hasCompletedOnboarding,
    bool? twoFactorEnabled,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool? bootstrapped,
    // Null already means "leave it alone" for both of these, so clearing
    // needs its own flag — the same reason BusinessProfile.clearLogo exists.
    bool clearLockout = false,
    bool clearActiveStaff = false,
  }) {
    return SessionState(
      savedProfileIds: savedProfileIds ?? this.savedProfileIds,
      activeStaffId: clearActiveStaff
          ? null
          : (activeStaffId ?? this.activeStaffId),
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      pin: pin ?? this.pin,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
      bootstrapped: bootstrapped ?? this.bootstrapped,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      listEquals(other.savedProfileIds, savedProfileIds) &&
      other.activeStaffId == activeStaffId &&
      other.isLoggedIn == isLoggedIn &&
      other.pin == pin &&
      other.isUnlocked == isUnlocked &&
      other.hasCompletedOnboarding == hasCompletedOnboarding &&
      other.twoFactorEnabled == twoFactorEnabled &&
      other.failedAttempts == failedAttempts &&
      other.lockedUntil == lockedUntil &&
      other.bootstrapped == bootstrapped;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(savedProfileIds),
    activeStaffId,
    isLoggedIn,
    pin,
    isUnlocked,
    hasCompletedOnboarding,
    twoFactorEnabled,
    failedAttempts,
    lockedUntil,
    bootstrapped,
  );
}
