import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/session.dart';
import 'package:restaurant_pos/providers/session_provider.dart';
import 'package:restaurant_pos/providers/settings_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/screens/auth/onboarding_screen.dart';
import 'package:restaurant_pos/screens/auth/otp_login_screen.dart';

/// Renders the auth and onboarding screens so their layout can be reviewed as
/// images rather than inferred from widget assertions.
///
/// Run with
/// `flutter test --update-goldens test/auth_screens_golden_test.dart`.

/// Best-effort path to the Flutter SDK, for loading the bundled icon font.
String _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  final dart = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  return dart.path;
}

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await inter.load();

    final iconFont = File(
      '${_flutterRoot()}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    if (iconFont.existsSync()) {
      final bytes = ByteData.sublistView(iconFont.readAsBytesSync());
      final icons = FontLoader('MaterialIcons')..addFont(Future.value(bytes));
      await icons.load();
    }
  });

  Future<ProviderContainer> pumpAuth(
    WidgetTester tester,
    Size size, {
    required String route,
    SessionState? session,
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).set(mode);
    if (session != null) {
      container.read(sessionProvider.notifier).state = session;
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RestaurantPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(route);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return container;
  }

  /// A device nobody has signed in on, past the splash.
  const fresh = SessionState(bootstrapped: true);

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/auth_$name.png'),
  );

  group('Phone entry', () {
    testWidgets('desktop light', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 900),
        route: AppRoute.loginPath,
        session: fresh,
      );
      await shoot(tester, 'phone_desktop_light');
    });

    testWidgets('desktop dark', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 900),
        route: AppRoute.loginPath,
        session: fresh,
        mode: ThemeMode.dark,
      );
      await shoot(tester, 'phone_desktop_dark');
    });

    testWidgets('tablet', (tester) async {
      await pumpAuth(
        tester,
        const Size(834, 1000),
        route: AppRoute.loginPath,
        session: fresh,
      );
      await shoot(tester, 'phone_tablet');
    });

    testWidgets('mobile', (tester) async {
      await pumpAuth(
        tester,
        const Size(390, 844),
        route: AppRoute.loginPath,
        session: fresh,
      );
      await shoot(tester, 'phone_mobile');
    });
  });

  group('Code entry', () {
    /// Drives the phone step so the OTP boxes are on screen, with a few digits
    /// filled — an empty row would not show the filled-box treatment.
    Future<void> reachCodeStep(WidgetTester tester) async {
      await tester.enterText(find.byKey(OtpLoginKeys.phone), '81234567890');
      await tester.tap(find.byKey(OtpLoginKeys.sendCode));
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byKey(OtpLoginKeys.digit(i)), '${i + 1}');
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('desktop light', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 900),
        route: AppRoute.loginPath,
        session: fresh,
      );
      await reachCodeStep(tester);
      await shoot(tester, 'code_desktop_light');
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('mobile', (tester) async {
      await pumpAuth(
        tester,
        const Size(390, 844),
        route: AppRoute.loginPath,
        session: fresh,
      );
      await reachCodeStep(tester);
      await shoot(tester, 'code_mobile');
      await tester.pump(const Duration(seconds: 31));
    });
  });

  group('Onboarding', () {
    final needsOnboarding = SessionNotifier.seed.copyWith(
      hasCompletedOnboarding: false,
      bootstrapped: true,
    );

    testWidgets('step 1 — desktop light', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 980),
        route: AppRoute.onboardingPath,
        session: needsOnboarding,
      );
      await shoot(tester, 'onboarding_1_desktop_light');
    });

    testWidgets('step 1 — desktop dark', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 980),
        route: AppRoute.onboardingPath,
        session: needsOnboarding,
        mode: ThemeMode.dark,
      );
      await shoot(tester, 'onboarding_1_desktop_dark');
    });

    testWidgets('step 4 team — desktop light', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 1180),
        route: AppRoute.onboardingPath,
        session: needsOnboarding,
      );

      // Walk to the team step. Every earlier step seeds from the providers, so
      // Continue is live without typing anything.
      for (var step = 0; step < 3; step++) {
        await tester.tap(find.byKey(OnboardingKeys.next));
        await tester.pumpAndSettle();
      }
      await shoot(tester, 'onboarding_4_desktop_light');
    });

    testWidgets('step 1 — mobile', (tester) async {
      await pumpAuth(
        tester,
        const Size(390, 940),
        route: AppRoute.onboardingPath,
        session: needsOnboarding,
      );
      await shoot(tester, 'onboarding_1_mobile');
    });
  });

  group('PIN', () {
    testWidgets('unlock — desktop light', (tester) async {
      await pumpAuth(
        tester,
        const Size(1440, 900),
        route: AppRoute.unlockPath,
        session: SessionNotifier.seed.copyWith(
          isUnlocked: false,
          bootstrapped: true,
        ),
      );
      await shoot(tester, 'unlock_desktop_light');
    });

    testWidgets('unlock — mobile', (tester) async {
      await pumpAuth(
        tester,
        const Size(390, 844),
        route: AppRoute.unlockPath,
        session: SessionNotifier.seed.copyWith(
          isUnlocked: false,
          bootstrapped: true,
        ),
      );
      await shoot(tester, 'unlock_mobile');
    });
  });
}
