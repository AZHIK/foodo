import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/profile_picker_screen.dart';
import '../../features/auth/presentation/screens/otp_login_screen.dart';

/// The single [GoRouter] instance for the app.
///
/// Placeholder typed routes — real screen implementations and
/// redirect guards (auth, profile-selection) will be added in later stages.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.profilePicker,
      builder: (_, __) => const ProfilePickerScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginOtp,
      builder: (_, __) => const OtpLoginScreen(),
    ),
  ],
);
