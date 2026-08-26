import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/providers/settings_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';

/// Renders the assembled dashboard so its layout can be reviewed as an image.
///
/// Run with
/// `flutter test --update-goldens test/dashboard_screen_golden_test.dart`.

/// Best-effort path to the Flutter SDK, for loading the bundled icon font.
String _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  // `Platform.resolvedExecutable` is the Dart binary inside the SDK during a
  // `flutter test` run, so the root is three directories up.
  final dart = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  return dart.path;
}

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await inter.load();

    // Icons render as empty squares in a golden unless the icon font is loaded
    // too — the test environment substitutes a placeholder font for everything
    // it is not given. Located via the SDK rather than hardcoded, so this
    // still works on another machine.
    final iconFont = File(
      '${_flutterRoot()}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    if (iconFont.existsSync()) {
      final bytes = ByteData.sublistView(iconFont.readAsBytesSync());
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(bytes));
      await icons.load();
    }
  });

  Future<ProviderContainer> pumpDashboard(
    WidgetTester tester,
    Size size, {
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).set(mode);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(AppRoute.dashboardPath);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return container;
  }

  testWidgets('dashboard — desktop light', (tester) async {
    await pumpDashboard(tester, const Size(1440, 1180));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_desktop_light.png'),
    );
  });

  testWidgets('dashboard — desktop dark', (tester) async {
    await pumpDashboard(tester, const Size(1440, 1180), mode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_desktop_dark.png'),
    );
  });

  testWidgets('dashboard — tablet', (tester) async {
    await pumpDashboard(tester, const Size(834, 1400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_tablet.png'),
    );
  });

  testWidgets('dashboard — mobile', (tester) async {
    await pumpDashboard(tester, const Size(390, 1500));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_mobile.png'),
    );
  });
}
