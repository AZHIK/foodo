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
import '../../shared/widgets/widgets.dart';
import '../router/app_routes.dart';

/// Main adaptive application shell wrapping primary feature destinations.
///
/// Navigation chrome varies by breakpoint:
/// - Phone width (<600px): Bottom Navigation Bar, via [AdaptiveScaffold].
///   Sidebar is fully absent at this width.
/// - Tablet width (600-899px): the same custom [_AppSidebar] as desktop, but
///   *collapsed* to an icon-only rail (no labels, no profile text) so it
///   stays out of the way of POS's product-grid + cart-panel content.
/// - Desktop width (>=900px): [_AppSidebar] expanded — profile card with
///   name/role, labelled nav rows, dark-pill active state, pinned "End
///   Shift" row.
///
/// [_AppSidebar] is a single widget across both the tablet and desktop
/// tiers — it just collapses/expands as width crosses 900px — rather than
/// swapping between two structurally different widget trees at that
/// boundary. That swap (this shell's previous approach: AdaptiveScaffold's
/// NavigationRail below 900px, a wholly separate custom Row above it) is
/// what made resizing across the boundary janky, since Flutter has to
/// tear down and remount an entirely different subtree on every frame the
/// drag crosses 900px. A single collapsing widget instead just relayouts.
///
/// Houses persistent active-profile identity and the offline status
/// indicator — folded into the sidebar at tablet/desktop width, shown in
/// the top app bar at phone width.
class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  static const List<ShellDestination> _destinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_outlined,
      route: AppRoutes.dashboard,
    ),
    ShellDestination(
      label: 'POS',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_outlined,
      route: AppRoutes.pos,
    ),
    ShellDestination(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_outlined,
      route: AppRoutes.inventory,
    ),
    ShellDestination(
      label: 'Staff',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people_outlined,
      route: AppRoutes.staff,
    ),
    ShellDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_outlined,
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
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= AppDimensions.breakpointTablet;
    final sidebarCollapsed = width < AppDimensions.breakpointDesktop;

    final authState = ref.watch(authProvider);
    final businessName = authState is SessionActive
        ? authState.profile.displayName
        : AppStrings.appName;

    final isOnline = ref.watch(connectivityProvider).value ?? true;

    if (showSidebar) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD,
                  AppDimensions.spaceMD,
                  0,
                  AppDimensions.spaceMD,
                ),
                child: _AppSidebar(
                  profileName: businessName,
                  destinations: _destinations,
                  selectedIndex: selectedIndex,
                  isOnline: isOnline,
                  collapsed: sidebarCollapsed,
                  onDestinationSelected: (i) => _onDestinationSelected(context, i),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

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
        onSelectedIndexChange: (index) =>
            _onDestinationSelected(context, index),
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
        // Only the phone tier is ever reached here — [showSidebar] above
        // already routes width>=600 to the custom sidebar — so medium/large
        // are unreachable dead breakpoints, kept only because
        // AdaptiveScaffold requires them.
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

/// A single primary shell destination — label, icon pair, and target route.
class ShellDestination {
  const ShellDestination({
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

/// Tablet/desktop sidebar: profile card, flat nav list with a dark-pill
/// active state, and a pinned "End Shift" row at the bottom.
///
/// Collapses to an icon-only rail ([collapsed]=true, 600-899px) and expands
/// to a labelled panel ([collapsed]=false, >=900px) — a single widget that
/// relayouts across that boundary rather than two different widget trees.
///
/// Only 5 flat destinations exist (Dashboard/POS/Inventory/Staff/Settings)
/// — far fewer than the reference's ~13 items across two labelled groups
/// ("Offering" / "Back Office"), so grouping is deliberately omitted here;
/// it would add a layer of visual hierarchy this nav is too short to need.
class _AppSidebar extends ConsumerWidget {
  const _AppSidebar({
    required this.profileName,
    required this.destinations,
    required this.selectedIndex,
    required this.isOnline,
    required this.collapsed,
    required this.onDestinationSelected,
  });

  final String profileName;
  final List<ShellDestination> destinations;
  final int selectedIndex;
  final bool isOnline;
  final bool collapsed;
  final ValueChanged<int> onDestinationSelected;

  static const double _expandedWidth = 224;
  static const double _collapsedWidth = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? _collapsedWidth : _expandedWidth,
      child: AppCard.elevated(
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.spaceLG,
          horizontal: collapsed ? AppDimensions.spaceXXS : AppDimensions.spaceSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXS,
              ),
              child: collapsed
                  ? Center(
                      child: Tooltip(
                        message: profileName,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            _initialsFor(profileName),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            _initialsFor(profileName),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profileName,
                                style: AppTextStyles.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                // Placeholder: business-role names aren't
                                // wired to the local profile model yet.
                                'Business Owner',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceXS,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed
                        ? AppDimensions.spaceXXS
                        : AppDimensions.spaceSM,
                    vertical: AppDimensions.spaceXXS,
                  ),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: collapsed
                      ? Tooltip(
                          message: 'Offline',
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 14,
                            color: cs.onErrorContainer,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 14,
                              color: cs.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: cs.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceLG),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: AppDimensions.spaceSM),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final d = destinations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spaceXXS),
                    child: _SidebarNavTile(
                      icon: index == selectedIndex ? d.selectedIcon : d.icon,
                      label: d.label,
                      active: index == selectedIndex,
                      collapsed: collapsed,
                      onTap: () => onDestinationSelected(index),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: AppDimensions.spaceSM),
            _SidebarNavTile(
              icon: Icons.logout_outlined,
              label: 'End Shift',
              active: false,
              collapsed: collapsed,
              onTap: () => _endShift(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  static String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _endShift(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'End Shift',
      message: "End your current shift? You'll need to enter your PIN to resume.",
      confirmLabel: 'End shift',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authProvider.notifier).endShift();
  }
}

/// A single sidebar row. The active destination renders as a filled,
/// dark-neutral pill (near-black background, white text/icon) — a
/// deliberate departure from the app's usual orange accent, matching the
/// reference exactly rather than reusing the brand colour here.
///
/// When [collapsed], only the icon renders (centred, wrapped in a
/// [Tooltip] for the label) so the rail stays icon-width.
class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDimensions.radiusMD);
    final fg = active ? cs.surface : cs.onSurface.withValues(alpha: 0.72);

    final row = collapsed
        ? Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceSM + 2,
            ),
            child: Icon(icon, size: 20, color: fg),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceSM,
              vertical: AppDimensions.spaceSM + 2,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );

    final tile = Material(
      color: active ? cs.onSurface : Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: row),
    );

    return collapsed ? Tooltip(message: label, child: tile) : tile;
  }
}
