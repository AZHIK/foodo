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
  static const String loginOtpSent = 'We sent a code to';
  static const String loginOtpResend = 'Resend code in';
  static const String loginOtpDidntReceive = 'Didn\'t receive the code?';
  static const String loginOtpVerify = 'Verify';
  static const String loginOtpBack = 'Back';
  static const String profilePickerTitle = 'Choose a profile';
  static const String profilePickerSubtitle =
      'Choose a staff member for this business';
  static const String profilePickerEmpty = 'No profiles yet. Add one to begin.';

  // ── PIN / lockout ─────────────────────────────────────────────
  static const String pinTitle = 'Enter your PIN';
  static const String pinSubtitle = 'Use your 4–6 digit PIN to continue';
  static const String pinUnlockTitle = 'Unlock to continue';
  static const String pinUnlockSubtitle = 'Enter your PIN to unlock';
  static const String pinSetTitle = 'Set your PIN';
  static const String pinSetSubtitle = 'Choose a 4–6 digit PIN';
  static const String pinSetConfirm = 'Confirm your PIN';
  static const String pinSetMismatch = 'PINs do not match. Try again.';
  static const String pinInvalidLength = 'PIN must be 4–6 digits';
  static const String pinInvalidFormat = 'PIN must contain only digits';
  static const String pinWrong = 'Incorrect PIN. Try again.';
  static const String pinLockedOutTitle = 'Too many attempts';
  static const String pinLockedOutMessage =
      'This profile is locked. Verify your phone to continue.';
  static const String pinLockedOutVerifyPhone = 'Verify Phone';
  static const String pinLockedOutSuccess = 'Profile unlocked. Set a new PIN.';
  static const String pinLockedOutBack = 'Choose another profile';

  // ── Set PIN flow ──────────────────────────────────────────────
  static const String pinSetDisplayNameHint = 'Your name (optional)';
  static const String pinSetContinue = 'Continue';

  // ── Business onboarding ───────────────────────────────────────
  static const String onboardingTitle = 'Set up your business';
  static const String onboardingSubtitle =
      'Tell us a little about your business to get started.';
  static const String onboardingStepOf = 'Step';
  static const String onboardingContinue = 'Continue';
  static const String onboardingBack = 'Back';
  static const String onboardingBusinessTypeStepTitle =
      'What kind of business is this?';
  static const String onboardingBusinessTypeStepSubtitle =
      'Choose the category that best describes your business.';
  static const String onboardingDetailsStepTitle = 'Business details';
  static const String onboardingDetailsStepSubtitle =
      'Your business will appear to customers and partners with these details.';
  static const String onboardingReviewStepTitle = 'Review and confirm';
  static const String onboardingReviewStepSubtitle =
      'Please review your details before creating your business.';
  static const String onboardingBusinessName = 'Business name';
  static const String onboardingBusinessNameHint = 'e.g. Mama Ngoja Eatery';
  static const String onboardingBusinessNameRequired =
      'Business name is required';
  static const String onboardingCity = 'City';
  static const String onboardingCityHint = 'e.g. Dar es Salaam';
  static const String onboardingCityRequired = 'City is required';
  static const String onboardingCountry = 'Country';
  static const String onboardingTaxId = 'Tax ID (optional)';
  static const String onboardingTaxIdHint = 'TIN / registration number';
  static const String onboardingBusinessTypeLabel = 'Business type';
  static const String onboardingBusinessTypeRequired =
      'Choose a business type to continue';
  static const String onboardingCreateBusiness = 'Create business';
  static const String onboardingRetrySession = 'Retry';
  static const String onboardingCreating = 'Creating your business…';
  static const String onboardingComplete =
      'Welcome! Your business is ready to go.';
  static const String onboardingNotStartedTitle = 'Almost there';
  static const String onboardingNotStartedMessage =
      'Finish setting up your business to continue.';

  // ── Account settings ──────────────────────────────────────────
  static const String settings = 'Settings';
  static const String profilePickerNewStaff = 'New user?';
  static const String profilePickerSignIn = 'Sign in with your number';

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
