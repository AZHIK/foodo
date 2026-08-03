/// Animation durations and sync-retry intervals.
///
/// Keeping these in a single file makes it easy to tune timing across
/// the whole app without hunting through individual widgets or services.
abstract final class AppDurations {
  AppDurations._();

  // ── Animation / transition ────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // ── Sync / retry intervals ────────────────────────────────────
  static const Duration syncInitialDelay = Duration(seconds: 5);
  static const Duration syncInterval = Duration(minutes: 15);
  static const Duration retryBaseDelay = Duration(seconds: 2);
  static const Duration retryMaxDelay = Duration(minutes: 2);

  // ── PIN lockout policy ────────────────────────────────────────
  /// Maximum consecutive failed PIN attempts before the profile is
  /// locked out and must re-verify via OTP.
  static const int maxPinAttempts = 5;

  /// Lockout has no timed expiry — it is only cleared by a successful OTP
  /// re-verification. This far-future offset encodes "locked until cleared
  /// via OTP" in the persisted `pin_locked_until` column, which the boot
  /// path checks on every restart.
  static const Duration pinLockoutIndefinite = Duration(days: 3650);
}
