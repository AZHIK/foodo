import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/app/theme/app_theme.dart';
import 'package:foodlink_business/app/router/app_router.dart';
import 'package:foodlink_business/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen displays app name and loading indicator',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );

    expect(find.text('FoodLink Business'), findsOneWidget);
    expect(find.text('Powering African food businesses'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App router resolves splash route without crashing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );

    expect(find.text('FoodLink Business'), findsOneWidget);
  });
}
