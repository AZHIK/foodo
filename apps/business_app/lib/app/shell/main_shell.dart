import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/sync/connectivity_service.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import '../router/app_routes.dart';

/// Main adaptive application shell wrapping primary feature destinations.
///
/// Built on [AdaptiveScaffold]:
/// - Phone width (<600px): Bottom Navigation Bar
/// - Tablet width (600px-900px): Navigation Rail
/// - Desktop width (>=900px): Extended Navigation Rail
///
/// Houses persistent active business context name and offline status indicator.
class MainShell extends ConsumerWidget {
  const MainShell({
    required this.child,
    super.key,
  });

  final Widget child;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: AppRoutes.dashboard,
    ),
    _ShellDestination(
      label: 'POS',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      route: AppRoutes.pos,
    ),
    _ShellDestination(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      route: AppRoutes.inventory,
    ),
    _ShellDestination(
      label: 'Staff',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      route: AppRoutes.staff,
    ),
    _ShellDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: AppRoutes.settings,
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _destinations.length; i++) {
      final r = _destinations[i].route;
      if (location == r || (r != '/' && location.startsWith(r))) {
        return i;
      }
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index >= 0 && index < _destinations.length) {
      context.go(_destinations[index].route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = _calculateSelectedIndex(context);

    final authState = ref.watch(authProvider);
    final businessName = authState is SessionActive
        ? authState.profile.displayName
        : AppStrings.appName;

    final isOnline = ref.watch(connectivityProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppDimensions.spaceMD,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXS),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.seedTerracotta, AppColors.seedSage],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            Text(
              businessName,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (!isOnline)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceMD),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceSM,
                  vertical: AppDimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 14,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: AdaptiveScaffold(
        selectedIndex: selectedIndex,
        onSelectedIndexChange: (index) => _onDestinationSelected(context, index),
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
        body: (_) => child,
        smallBreakpoint: const Breakpoint(
          beginWidth: 0,
          endWidth: AppDimensions.breakpointTablet,
        ),
        mediumBreakpoint: const Breakpoint(
          beginWidth: AppDimensions.breakpointTablet,
          endWidth: AppDimensions.breakpointDesktop,
        ),
        largeBreakpoint: const Breakpoint(
          beginWidth: AppDimensions.breakpointDesktop,
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
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
