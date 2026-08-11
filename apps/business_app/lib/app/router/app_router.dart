import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../shell/main_shell.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/profile_picker_screen.dart';
import '../../features/auth/presentation/screens/otp_login_screen.dart';
import '../../features/auth/presentation/screens/pin_unlock_screen.dart';
import '../../features/auth/presentation/screens/set_pin_screen.dart';
import '../../features/auth/presentation/screens/account_settings_screen.dart';
import '../../features/business/presentation/screens/business_onboarding_screen.dart';
import '../../features/inventory/presentation/screens/inventory_list_screen.dart';
import '../../features/inventory/presentation/screens/item_form_screen.dart';
import '../../features/inventory/presentation/screens/item_detail_screen.dart';
import '../../shared/widgets/cards/app_card.dart';
import '../../shared/widgets/app_empty_state.dart';

/// Builds a new [GoRouter] instance wired to the auth state machine.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefresh(),
    redirect: (context, state) {
      final authState = ProviderScope.containerOf(context, listen: false)
          .read(authProvider);
      final location = state.matchedLocation;

      if (location == AppRoutes.splash) {
        return null;
      }

      // Authenticated but not yet set up: the only reachable destination is
      // the business-onboarding flow. Anything else (dashboard, settings,
      // another auth route) bounces back here until onboarding completes.
      if (authState is OnboardingRequired) {
        if (location != AppRoutes.businessOnboarding) {
          return AppRoutes.businessOnboarding;
        }
        return null;
      }

      final isAuthRoute = _isAuthRoute(location);
      final isAuthState = _isAuthenticated(authState);

      if (!isAuthState && !isAuthRoute) return AppRoutes.loginOtp;
      if (isAuthState && isAuthRoute) {
        return authState.when(
          sessionActive: (_, locked) =>
              locked ? AppRoutes.pinUnlock : AppRoutes.dashboard,
          profilesAvailable: (_) {
            final pendingProfileId = ProviderScope.containerOf(context, listen: false)
                .read(authProvider.notifier)
                .pendingProfileId;
            if (pendingProfileId != null &&
                location == AppRoutes.pinUnlock) {
              return null;
            }
            return AppRoutes.profilePicker;
          },
          otpPending: (_) => AppRoutes.loginOtp,
          settingPin: (_, _, _) => AppRoutes.setPin,
          pinLockedOut: (_, _) => AppRoutes.pinUnlock,
          onboardingRequired: (_) => AppRoutes.businessOnboarding,
          unauthenticated: () => AppRoutes.loginOtp,
        );
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.profilePicker, builder: (_, _) => const ProfilePickerScreen()),
      GoRoute(path: AppRoutes.loginOtp, builder: (_, _) => const OtpLoginScreen()),
      GoRoute(path: AppRoutes.setPin, builder: (_, _) => const SetPinScreen()),
      GoRoute(path: AppRoutes.pinUnlock, builder: (_, _) => const PinUnlockScreen()),
      GoRoute(path: AppRoutes.businessOnboarding, builder: (_, _) => const BusinessOnboardingScreen()),
      
      // Main Application Shell Route
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, _) => const _PlaceholderScreen(
              title: 'Dashboard',
              icon: Icons.dashboard_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.pos,
            builder: (_, _) => const _PlaceholderScreen(
              title: 'POS',
              icon: Icons.point_of_sale_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            builder: (_, _) => const InventoryListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const ItemFormScreen(mode: ItemFormMode.add),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final itemId = state.pathParameters['id'] ?? '';
                  return ItemDetailScreen(itemId: itemId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final itemId = state.pathParameters['id'] ?? '';
                      return ItemFormScreen(
                        mode: ItemFormMode.edit,
                        itemId: itemId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.staff,
            builder: (_, _) => const _PlaceholderScreen(
              title: 'Staff',
              icon: Icons.people_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const AccountSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountSettings,
            builder: (_, _) => const AccountSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

final GoRouter appRouter = createAppRouter();

bool _isAuthRoute(String location) => location == AppRoutes.loginOtp ||
    location == AppRoutes.setPin ||
    location == AppRoutes.pinUnlock ||
    location == AppRoutes.businessOnboarding;

bool _isAuthenticated(AuthState state) => state.when(
      unauthenticated: () => false,
      profilesAvailable: (_) => true,
      sessionActive: (_, _) => true,
      otpPending: (_) => true,
      settingPin: (_, _, _) => true,
      pinLockedOut: (_, _) => true,
      onboardingRequired: (_) => true,
    );

class _RouterRefresh extends ChangeNotifier {}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: 'This module is scheduled for development in a future stage.',
      action: AppCard.outlined(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
          vertical: AppDimensions.spaceMD,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_outlined, size: 18, color: colorScheme.primary),
            const SizedBox(width: AppDimensions.spaceSM),
            Text(
              'Coming Soon',
              style: AppTextStyles.labelLarge.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}