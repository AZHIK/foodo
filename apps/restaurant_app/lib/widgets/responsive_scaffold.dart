import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import 'app_top_bar.dart';
import 'brand_mark.dart';
import 'nav_shell_scope.dart';

@immutable
class NavDestinationSpec {
  const NavDestinationSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Width of the rail once extended. NavigationRail's API takes this as a
/// concrete number, so the header derives its own width from the same
/// constant rather than guessing.
const double _railExtendedWidth = 212;
const double _railCollapsedWidth = 76;

/// Order matters — these line up index-for-index with the shell branches in
/// [goRouterProvider].
const _destinations = <NavDestinationSpec>[
  NavDestinationSpec(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  NavDestinationSpec(
    label: 'POS',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
  ),
  NavDestinationSpec(
    label: 'Sales',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  NavDestinationSpec(
    label: 'Customers',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
  ),
  NavDestinationSpec(
    label: 'Reorders',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart_rounded,
  ),
  NavDestinationSpec(
    label: 'Couriers',
    icon: Icons.two_wheeler_outlined,
    selectedIcon: Icons.two_wheeler_rounded,
  ),
  NavDestinationSpec(
    label: 'Finance',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
  ),
  NavDestinationSpec(
    label: 'Reports',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  NavDestinationSpec(
    label: 'Insights',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
  ),
  NavDestinationSpec(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  NavDestinationSpec(
    label: 'Staff',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
  ),
  NavDestinationSpec(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];

/// The POS tab carries the open-order badge. Second in the list, since the
/// dashboard took the first slot.
const _cartBadgeIndex = 1;

/// Hosts the shell branches and swaps navigation affordances by width:
/// bottom bar on phones, a hamburger drawer on tablets, and a persistent rail
/// on desktop that extends to labels once there is room. The branch
/// [Navigator]s are untouched in every case, so state survives the switch.
class ResponsiveScaffold extends ConsumerStatefulWidget {
  const ResponsiveScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onDestinationSelected(int index) {
    // `initialLocation: true` when re-tapping the active tab pops that branch
    // back to its root — the standard "tap to go home" behaviour.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onDrawerDestinationSelected(int index) {
    Navigator.of(context).pop();
    _onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final form = Breakpoints.of(constraints.maxWidth);
        final index = widget.navigationShell.currentIndex;

        final body = NavShellScope(
          hasDrawer: form.isTablet,
          openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          child: widget.navigationShell,
        );

        final scaffold = switch (form) {
          FormFactor.mobile => Scaffold(
            key: _scaffoldKey,
            body: body,
            bottomNavigationBar: _BottomNav(
              currentIndex: index,
              onSelected: _onDestinationSelected,
            ),
          ),

          // Tablet trades the rail for a drawer: at 600–1024 the ~76px rail is
          // width the item grid and cart panel need more than navigation does.
          FormFactor.tablet => Scaffold(
            key: _scaffoldKey,
            drawer: _NavDrawer(
              currentIndex: index,
              onSelected: _onDrawerDestinationSelected,
            ),
            body: body,
          ),

          FormFactor.desktop => Scaffold(
            key: _scaffoldKey,
            body: SafeArea(
              child: Row(
                children: [
                  _SideRail(
                    currentIndex: index,
                    onSelected: _onDestinationSelected,
                    extended: constraints.maxWidth >= Breakpoints.extendedRail,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        };

        return Column(
          children: [
            const AppTopBar(),
            Expanded(child: scaffold),
          ],
        );
      },
    );
  }
}

/// Destinations the phone's bottom bar shows directly, by index into
/// [_destinations]. The rest live behind "More".
///
/// Eight tabs across a 360px bar leaves each one about 45px, which clips the
/// longer labels and puts every target under the comfortable touch size. Five
/// is what the bar can actually hold, so the four a counter uses hourly stay
/// on it and the occasional ones move one tap further away.
///
/// Indices into [_destinations]: Home, POS, Sales, Inventory.
const _mobilePrimary = <int>[0, 1, 2, 6];

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Index of the "More" slot — always last on the bar.
  int get _moreSlot => _mobilePrimary.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    // A destination reached through "More" keeps that slot highlighted, so the
    // bar never shows nothing selected.
    final slot = _mobilePrimary.indexOf(currentIndex);
    final selected = slot == -1 ? _moreSlot : slot;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.semantic.hairline)),
      ),
      child: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (tapped) => tapped == _moreSlot
            ? _openMore(context)
            : onSelected(_mobilePrimary[tapped]),
        destinations: [
          for (final i in _mobilePrimary)
            NavigationDestination(
              icon: _badged(Icon(_destinations[i].icon), i, cartCount),
              selectedIcon: _badged(
                Icon(_destinations[i].selectedIcon),
                i,
                cartCount,
              ),
              label: _destinations[i].label,
              tooltip: _destinations[i].label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
            tooltip: 'More destinations',
          ),
        ],
      ),
    );
  }

  Future<void> _openMore(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                0,
                Insets.xl,
                Insets.sm,
              ),
              child: Text(
                'Go to',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Every destination, not only the overflow ones — a menu that
                    // hides where you already are is harder to orient in.
                    for (var i = 0; i < _destinations.length; i++)
                      ListTile(
                        leading: Icon(
                          i == currentIndex
                              ? _destinations[i].selectedIcon
                              : _destinations[i].icon,
                        ),
                        title: Text(_destinations[i].label),
                        selected: i == currentIndex,
                        onTap: () => Navigator.of(sheetContext).pop(i),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Insets.md),
              child: _ThemeToggleTile(),
            ),
            const SizedBox(height: Insets.sm),
          ],
        ),
      ),
    );

    if (picked != null) onSelected(picked);
  }
}

class _NavDrawer extends ConsumerWidget {
  const _NavDrawer({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return NavigationDrawer(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(Insets.xl, Insets.xl, Insets.xl, Insets.sm),
          child: BrandLockup(),
        ),
        for (var i = 0; i < _destinations.length; i++)
          NavigationDrawerDestination(
            icon: _badged(Icon(_destinations[i].icon), i, cartCount),
            selectedIcon: _badged(
              Icon(_destinations[i].selectedIcon),
              i,
              cartCount,
            ),
            label: Text(_destinations[i].label),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(Insets.xl, Insets.md, Insets.xl, Insets.sm),
          child: Divider(),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Insets.md),
          child: _ThemeToggleTile(),
        ),
      ],
    );
  }
}

class _SideRail extends ConsumerWidget {
  const _SideRail({
    required this.currentIndex,
    required this.onSelected,
    required this.extended,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final cartCount = ref.watch(cartItemCountProvider);
    final themeMode = ref.watch(themeModeProvider);

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      extended: extended,
      minWidth: _railCollapsedWidth,
      minExtendedWidth: _railExtendedWidth,
      groupAlignment: -0.9,
      // Lets the destination group scroll on a short window — a 320px-tall
      // terminal would otherwise overflow the rail rather than clip it.
      scrollable: true,
      leading: _RailHeader(extended: extended),
      // No Expanded here: the rail already bottom-aligns `trailing`, and a
      // flex child would split the rail's height with the destinations
      // instead of taking only what it needs.
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: Insets.lg, top: Insets.sm),
        child: IconButton(
          tooltip: switch (themeMode) {
            ThemeMode.system => 'Theme: follow system',
            ThemeMode.light => 'Theme: light',
            ThemeMode.dark => 'Theme: dark',
          },
          onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
          icon: Icon(switch (themeMode) {
            ThemeMode.system => Icons.brightness_auto_rounded,
            ThemeMode.light => Icons.light_mode_rounded,
            ThemeMode.dark => Icons.dark_mode_rounded,
          }),
          color: colors.onSurfaceVariant,
        ),
      ),
      destinations: [
        for (var i = 0; i < _destinations.length; i++)
          NavigationRailDestination(
            icon: _badged(Icon(_destinations[i].icon), i, cartCount),
            selectedIcon: _badged(
              Icon(_destinations[i].selectedIcon),
              i,
              cartCount,
            ),
            label: Text(_destinations[i].label),
            padding: const EdgeInsets.symmetric(vertical: Insets.xs),
          ),
      ],
    );
  }
}

/// Wraps an icon in the open-order count, but only for the POS destination.
Widget _badged(Widget icon, int index, int cartCount) {
  if (index != _cartBadgeIndex || cartCount == 0) return icon;
  return Badge.count(count: cartCount, child: icon);
}

class _ThemeToggleTile extends ConsumerWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      leading: Icon(switch (themeMode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      }),
      title: Text(switch (themeMode) {
        ThemeMode.system => 'Follow system',
        ThemeMode.light => 'Light theme',
        ThemeMode.dark => 'Dark theme',
      }),
      onTap: () => ref.read(themeModeProvider.notifier).cycle(),
    );
  }
}

/// Brand mark at the top of the rail. Collapses to just the mark when the rail
/// is not extended.
class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.xl,
        Insets.md,
        Insets.xl,
      ),
      child: extended
          // NavigationRail lays its `leading` out with unbounded width while
          // measuring, so the Row needs a bound of its own before Expanded
          // can mean anything.
          ? const SizedBox(
              width: _railExtendedWidth - Insets.md * 2,
              child: BrandLockup(),
            )
          : const BrandMark(),
    );
  }
}
