import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/profile_picker_screen.dart';
import '../../features/auth/presentation/screens/otp_login_screen.dart';
import '../../features/auth/presentation/screens/pin_unlock_screen.dart';
import '../../features/auth/presentation/screens/set_pin_screen.dart';
import '../../features/auth/presentation/screens/account_settings_screen.dart';
import '../../shared/widgets/widgets.dart';

/// Builds a new [GoRouter] instance wired to the auth state machine.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefresh(),
    redirect: (context, state) {
      final authState = ProviderScope.containerOf(context, listen: false)
          .read(authProvider);

      final isAuthRoute = _isAuthRoute(state.matchedLocation);
      final isAuthState = _isAuthenticated(authState);

      if (state.matchedLocation == AppRoutes.splash) {
        return null;
      }
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
                state.matchedLocation == AppRoutes.pinUnlock) {
              return null;
            }
            return AppRoutes.profilePicker;
          },
          otpPending: (_) => AppRoutes.loginOtp,
          settingPin: (_, _, _) => AppRoutes.setPin,
          pinLockedOut: (_, _) => AppRoutes.pinUnlock,
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
      GoRoute(path: AppRoutes.dashboard, builder: (_, _) => const _AppShell(initialIndex: 0)),
      GoRoute(path: AppRoutes.pos, builder: (_, _) => const _AppShell(initialIndex: 1)),
      GoRoute(path: AppRoutes.inventory, builder: (_, _) => const _AppShell(initialIndex: 2)),
      GoRoute(path: AppRoutes.staff, builder: (_, _) => const _AppShell(initialIndex: 3)),
      GoRoute(path: AppRoutes.accountSettings, builder: (_, _) => const AccountSettingsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const AccountSettingsScreen()),
    ],
  );
}

final GoRouter appRouter = createAppRouter();

bool _isAuthRoute(String location) => location == AppRoutes.loginOtp ||
    location == AppRoutes.setPin ||
    location == AppRoutes.pinUnlock;

bool _isAuthenticated(AuthState state) => state.when(
      unauthenticated: () => false,
      profilesAvailable: (_) => true,
      sessionActive: (_, _) => true,
      otpPending: (_) => true,
      settingPin: (_, _, _) => true,
      pinLockedOut: (_, _) => true,
    );

class _RouterRefresh extends ChangeNotifier {}

// ── Destination model ───────────────────────────────────────────────────────

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

const _destinations = [
  _Destination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: AppRoutes.dashboard,
  ),
  _Destination(
    label: 'POS',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    route: AppRoutes.pos,
  ),
  _Destination(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    route: AppRoutes.inventory,
  ),
  _Destination(
    label: 'Staff',
    icon: Icons.people_outlined,
    selectedIcon: Icons.people,
    route: AppRoutes.staff,
  ),
];

// ── App shell — NavRail (tablet/desktop) or BottomNav (mobile) ─────────────

class _AppShell extends StatefulWidget {
  const _AppShell({required this.initialIndex});
  final int initialIndex;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    context.go(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppDimensions.breakpointTablet;

    final body = _PlaceholderBody(
      index: _selectedIndex,
      destination: _destinations[_selectedIndex],
    );

    if (!isWide) {
      // Mobile — bottom nav
      return Scaffold(
        body: body,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _navigate,
            items: [
              for (final d in _destinations)
                BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  activeIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    // Tablet / desktop — navigation rail
    final isDesktop = width >= AppDimensions.breakpointDesktop;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _navigate,
            extended: isDesktop,
            minWidth: AppDimensions.navRailWidth,
            minExtendedWidth: 180,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.seedTerracotta, AppColors.seedSage],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: AppDimensions.spaceSM),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceLG),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: AppStrings.settings,
                    onPressed: () => context.go(AppRoutes.settings),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ── Branded placeholder body ────────────────────────────────────────────────

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({required this.index, required this.destination});
  final int index;
  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(destination.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings,
            onPressed: () => context.go(AppRoutes.settings),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
        ],
      ),
      body: AppEmptyState(
        icon: destination.selectedIcon,
        title: destination.label,
        subtitle: 'This section is under construction and will be available in a future release.',
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
                'Stage 4+',
                style: AppTextStyles.labelLarge.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}