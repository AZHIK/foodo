import 'package:flutter/material.dart';

/// Lets a screen's own top bar drive the navigation shell that hosts it.
///
/// On tablet the shell owns the drawer, but each screen owns its header (the
/// POS search bar and the Sales filter bar look nothing alike). Rather than
/// hoisting a shared AppBar into the shell and contorting both screens to fit,
/// the shell publishes its drawer through this scope and screens drop a
/// [NavMenuButton] into whatever header they already have.
class NavShellScope extends InheritedWidget {
  const NavShellScope({
    super.key,
    required this.hasDrawer,
    required this.openDrawer,
    required super.child,
  });

  /// True only on the tablet breakpoint, where navigation lives behind a
  /// hamburger instead of a persistent rail or bottom bar.
  final bool hasDrawer;
  final VoidCallback openDrawer;

  static NavShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavShellScope>();

  @override
  bool updateShouldNotify(NavShellScope oldWidget) =>
      hasDrawer != oldWidget.hasDrawer || openDrawer != oldWidget.openDrawer;
}

/// Hamburger that shows itself only where the shell actually has a drawer, so
/// screens can place it unconditionally and let the breakpoint decide.
class NavMenuButton extends StatelessWidget {
  const NavMenuButton({super.key, this.padding = const EdgeInsets.only(right: 4)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scope = NavShellScope.maybeOf(context);
    if (scope == null || !scope.hasDrawer) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: IconButton(
        onPressed: scope.openDrawer,
        icon: const Icon(Icons.menu_rounded),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
    );
  }
}
