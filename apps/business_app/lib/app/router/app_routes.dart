/// Typed route-path constants used throughout the app.
///
/// Centralising path strings here guarantees a single source of truth
/// and makes future deep-link / go_router typed-ref migrations easier.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String profilePicker = '/profile-picker';
  static const String loginOtp = '/login-otp';
  static const String setPin = '/set-pin';
  static const String pinUnlock = '/pin-unlock';
  static const String dashboard = '/dashboard';
  static const String pos = '/pos';
  static const String inventory = '/inventory';
  static const String staff = '/staff';
  static const String settings = '/settings';
  static const String accountSettings = '/account-settings';
}
