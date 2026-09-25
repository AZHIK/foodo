import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_pos/constants/app_strings.dart';
import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/models/store_location.dart';
import 'package:restaurant_pos/models/store_settings.dart';
import 'package:restaurant_pos/providers/auth_provider.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/settings_provider.dart';
import 'package:restaurant_pos/providers/store_settings_hydration.dart';
import 'package:restaurant_pos/screens/settings/store_switch_flow.dart';

import 'test_helpers/fake_identity_backend.dart';

/// In-memory stand-in for `flutter_secure_storage`'s platform channel —
/// same shape as `mockSecureStorage` in `auth_flow_test.dart` (kept local
/// so this file doesn't import another test file).
void _mockSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final values = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    switch (call.method) {
      case 'write':
        values[args['key'] as String] = args['value'] as String;
        return null;
      case 'read':
        return values[args['key'] as String];
      case 'delete':
        values.remove(args['key'] as String);
        return null;
      case 'deleteAll':
        values.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(values);
      case 'containsKey':
        return values.containsKey(args['key'] as String);
      default:
        return null;
    }
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
}

void main() {
  testWidgets(
    'switching stores moves tokens, device, settings and lands on dashboard',
    (tester) async {
      _mockSecureStorage();
      final backend = FakeIdentityBackendState()
        ..needsOnboarding = false
        ..businessId = 'biz-1'
        ..businessName = 'The Copper Fig';

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          identityServiceDioProvider.overrideWithValue(
            Dio()..httpClientAdapter = FakeIdentityAdapter(backend),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authProvider.notifier);

      // Awaiting notifier futures directly can deadlock in FakeAsync (see
      // auth_flow_test's `pumped`): start, settle, then collect.
      Future<T> pumped<T>(Future<T> Function() action) async {
        final future = action();
        await tester.pumpAndSettle();
        return future;
      }

      await pumped(() => notifier.requestOtp('712345678'));
      await pumped(() => notifier.verifyOtp(fakeOtpCode));
      // Set PIN creates the local profile row the permission cache's FK
      // needs — same order as production (PIN before any switch).
      await pumped(() => notifier.setPin('135790'));

      // Invited-staff path context-switches at login: the terminal starts
      // locked to the primary store.
      expect(container.read(authProvider).selectedStoreId, 'store-1');

      const target = StoreLocation(
        id: 'store-2',
        businessId: 'biz-1',
        name: 'Branch Two',
        token: 'tok-2',
        locationType: LocationType.restaurantBranch,
        status: StoreStatus.active,
        countryCode: 'TZ',
        timezone: 'Africa/Dar_es_Salaam',
        isPrimary: false,
      );

      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => runStoreSwitchFlow(context, ref, target),
                  child: const Text('GO'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) =>
                const Scaffold(body: Text('DASHBOARD')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Cart empty and outbox clean: straight to the pre-flight sheet.
      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.switchToStoreTitle('Branch Two')),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.switchStoreAction));
      await tester.pumpAndSettle();

      // Tokens + selection moved…
      expect(container.read(authProvider).selectedStoreId, 'store-2');
      // …the device pointer followed…
      final device = await db.select(db.deviceConfig).getSingle();
      expect(device.businessLocationId, 'store-2');
      // …the new store's backend settings hydrated (fake serves USD)…
      expect(container.read(storeSettingsProvider).currency, Currency.usd);
      expect(container.read(storeSettingsProvider).taxInclusive, isTrue);
      // …no pending-token banner (the fake exchange succeeded)…
      expect(
        container.read(storeTokenRefreshPendingProvider),
        isFalse,
      );
      // …the switch was audited…
      final audit = await db.select(db.localAuditLog).get();
      expect(audit.where((a) => a.action == 'store.switched'), hasLength(1));
      // …and the app landed on the dashboard as the new store.
      expect(find.text('DASHBOARD'), findsOneWidget);
    },
  );
}
