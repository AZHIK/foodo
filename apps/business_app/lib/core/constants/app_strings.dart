/// Centralised copy text for the entire app.
///
/// Plain Dart `static const` strings are used for Stage 1 to keep
/// the structure lightweight.  When the app is ready for localisation
/// the values here can be mechanically migrated to ARB / l10n
/// generated classes without touching the widgets that reference them.
abstract final class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────────────────
  static const String appName = 'FoodLink Business';
  static const String appTagline = 'Powering African food businesses';

  // ── Auth / splash ─────────────────────────────────────────────
  static const String splashLoading = 'Loading…';
  static const String loginTitle = 'Sign in';
  static const String loginOtpHint = 'Enter the code sent to your phone';
  static const String profilePickerTitle = 'Choose a profile';
  static const String profilePickerSubtitle =
      'Which business are you working with today?';

  // ── Errors ────────────────────────────────────────────────────
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError =
      'Something went wrong on our end. Please try again.';
  static const String authError = 'Session expired. Please sign in again.';
  static const String unknownError = 'An unexpected error occurred.';

  // ── Sync ──────────────────────────────────────────────────────
  static const String syncing = 'Syncing…';
  static const String syncComplete = 'All changes saved';
  static const String syncFailed = 'Sync failed. Will retry shortly.';
  static const String offline = 'You are offline';
}
