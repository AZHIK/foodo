/// Every [Duration] the app uses, in one place.
///
/// Animation timings read as intent (`quick` vs `relaxed`) instead of raw
/// milliseconds scattered across widgets, and operational timings (timeouts,
/// TTLs, cooldowns) stop drifting apart when three Dio clients each need
/// "the same" 10/30/30 seconds. Nothing here is widget-specific state —
/// these are the app's shared sense of time.
library;

abstract final class AppDurations {
  // -------------------------------------------------------------------------
  // Micro-interactions (tap feedback, digit transitions)
  // -------------------------------------------------------------------------

  /// Press-scale on tappable cards.
  static const micro = Duration(milliseconds: 90);

  /// Digit fades, key presses, card highlight pops.
  static const quick = Duration(milliseconds: 140);

  /// Panel slides, chart animations.
  static const snappy = Duration(milliseconds: 150);

  /// Auth step transitions.
  static const authStep = Duration(milliseconds: 180);

  /// Auth screen transitions, fade-outs.
  static const screen = Duration(milliseconds: 220);

  /// Sidebar / aside motion.
  static const aside = Duration(milliseconds: 240);

  /// Step-progress animation.
  static const stepBar = Duration(milliseconds: 260);

  /// Dialog entrance.
  static const dialog = Duration(milliseconds: 300);

  /// Error shake, post-action navigation pause.
  static const shake = Duration(milliseconds: 420);

  /// Splash brand moment.
  static const splashBrand = Duration(milliseconds: 1200);

  /// How long the "saved" tick stays up.
  static const savedTickHold = Duration(milliseconds: 1400);

  /// Tooltip long-press wait.
  static const tooltipWait = Duration(seconds: 1);

  // -------------------------------------------------------------------------
  // Network
  // -------------------------------------------------------------------------

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 30);

  // -------------------------------------------------------------------------
  // Auth / session
  // -------------------------------------------------------------------------

  /// Server session lifetime — also the assumed access-token TTL wherever
  /// the expiry must be anticipated client-side.
  static const sessionLifetime = Duration(minutes: 15);

  /// Refresh ahead of actual expiry by this much.
  static const tokenRefreshSkew = Duration(minutes: 5);

  /// Tolerance when decoding a JWT's expiry locally.
  static const jwtDecodeSkew = Duration(seconds: 1);

  /// PIN lockout after exhausting attempts.
  static const pinLockout = Duration(seconds: 30);

  /// One-second tickers (OTP cooldown, lockout countdown).
  static const ticker = Duration(seconds: 1);

  /// OTP resend cooldown.
  static const otpResendCooldown = Duration(seconds: 30);

  /// Simulated verification latency on the OTP screen.
  static const otpFakeVerifyDelay = Duration(milliseconds: 800);

  /// Step-advance pause on the set-PIN flow.
  static const setPinStepDelay = Duration(milliseconds: 180);

  // -------------------------------------------------------------------------
  // Sync / cache
  // -------------------------------------------------------------------------

  static const permissionsCacheTtl = Duration(hours: 24);
  static const onShiftWindow = Duration(hours: 12);
  static const backgroundSyncInterval = Duration(minutes: 15);
  static const syncPollDelay = Duration(seconds: 2);
  static const mockChatReplyDelay = Duration(milliseconds: 500);
  static const accountSaveDebounce = Duration(milliseconds: 600);

  // -------------------------------------------------------------------------
  // Feedback
  // -------------------------------------------------------------------------

  static const aiSnackbar = Duration(seconds: 5);
  static const exportSnackbarOk = Duration(seconds: 10);
  static const exportSnackbarError = Duration(seconds: 6);

  // -------------------------------------------------------------------------
  // Report / history windows
  // -------------------------------------------------------------------------

  /// Default Reports window: last 30 days (29 back + today).
  static const reportsDefaultLookback = Duration(days: 29);

  /// Waste / production history windows.
  static const analyticsWindow = Duration(days: 30);

  /// Single-day sales windows.
  static const singleDay = Duration(days: 1);

  /// Default supplier lead time when none is entered.
  static const defaultLeadTime = Duration(days: 7);
}
