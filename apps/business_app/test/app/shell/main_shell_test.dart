import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:foodlink_business/app/router/app_routes.dart';
import 'package:foodlink_business/app/shell/main_shell.dart';
import 'package:foodlink_business/core/sync/connectivity_service.dart';

Widget _buildTestShell({
  required Size size,
  String initialLocation = '/inventory',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('Dashboard Screen'))),
          ),
          GoRoute(
            path: AppRoutes.pos,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('POS Screen'))),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('Inventory Screen'))),
          ),
          GoRoute(
            path: AppRoutes.staff,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('Staff Screen'))),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('Settings Screen'))),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      // connectivity_plus has no platform channel in tests; force online.
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('MainShell Navigation & Layout Tests', () {
    testWidgets('renders shell destinations and navigates on phone breakpoint',
        (tester) async {
      const phoneSize = Size(390, 844);
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestShell(size: phoneSize));
      await tester.pumpAndSettle();

      expect(find.text('FoodLink Business'), findsOneWidget);
      expect(find.text('Inventory Screen'), findsOneWidget);
      expect(find.text('Inventory'), findsWidgets);
      expect(find.text('Dashboard'), findsWidgets);
      // Phones get a bottom navigation bar.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Tap Dashboard destination
      await tester.tap(find.text('Dashboard').last);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets(
      'collapses the sidebar to an icon rail on the tablet breakpoint (600-899px)',
      (tester) async {
        const tabletSize = Size(760, 900);
        tester.view.physicalSize = tabletSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildTestShell(size: tabletSize));
        await tester.pumpAndSettle();

        expect(find.text('Inventory Screen'), findsOneWidget);
        // Tablet uses the same custom sidebar as desktop, just collapsed to
        // an icon-only rail — not AdaptiveScaffold's NavigationRail, and
        // not a structurally different widget tree from desktop's (that's
        // what made resizing across 900px unstable before).
        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        // Collapsed: labels are hidden, only icon + tooltip remain.
        expect(find.text('Dashboard'), findsNothing);
        expect(find.text('End Shift'), findsNothing);
        expect(find.byTooltip('POS'), findsOneWidget);

        await tester.tap(find.byTooltip('POS'));
        await tester.pumpAndSettle();

        expect(find.text('POS Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'expands the sidebar with labels on the desktop breakpoint (>=900px)',
      (tester) async {
        const desktopSize = Size(1200, 900);
        tester.view.physicalSize = desktopSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildTestShell(size: desktopSize));
        await tester.pumpAndSettle();

        expect(find.text('Inventory Screen'), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        // Expanded: profile card (name) and pinned "End Shift" row, both
        // with visible labels this time.
        expect(find.text('FoodLink Business'), findsOneWidget);
        expect(find.text('End Shift'), findsOneWidget);

        // Tap POS destination in the sidebar.
        await tester.tap(find.text('POS').last);
        await tester.pumpAndSettle();

        expect(find.text('POS Screen'), findsOneWidget);
      },
    );
  });
}
