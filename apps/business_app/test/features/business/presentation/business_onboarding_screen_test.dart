import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/app/router/app_router.dart';
import 'package:foodlink_business/app/theme/app_theme.dart';
import 'package:foodlink_business/core/constants/app_strings.dart';
import 'package:foodlink_business/core/error/failure.dart';
import 'package:foodlink_business/core/network/token_store.dart';
import 'package:foodlink_business/core/security/pin_service.dart';
import 'package:foodlink_business/core/storage/secure_storage_service.dart';
import 'package:foodlink_business/features/auth/application/auth_notifier.dart';
import 'package:foodlink_business/features/auth/data/identity_api.dart';
import 'package:foodlink_business/features/auth/data/local_profile_repository.dart';
import 'package:foodlink_business/features/auth/domain/auth_state.dart';
import 'package:foodlink_business/features/business/data/business_api.dart';
import 'package:foodlink_business/features/business/domain/business_type.dart';
import 'package:foodlink_business/features/business/presentation/screens/business_onboarding_screen.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('BusinessOnboardingScreen', () {
    testWidgets(
        'a mid-onboarding restart is routed back to onboarding, then '
        'completing the form creates the business and reaches sessionActive',
        (tester) async {
      // Tall viewport so every step of the form fits without scrolling.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const userId = 'u1';
      // Simulates an app kill mid-onboarding: the profile is active, the
      // refresh token is stored, but no business exists yet.
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: userId,
          phone: '+255700000001',
          displayName: 'Ama',
          pin: '1234',
          active: true,
        );
      final storage = FakeSecureStorageService()..tokens[userId] = 'rt_1';
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
        needsOnboardingAfterBusinessCreation: false,
        businessIdAfterCreation: 'biz_1',
        businessNameAfterCreation: 'Test Business',
      );
      final businessApi = FakeBusinessApi();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localProfileRepositoryProvider.overrideWithValue(repository),
            pinServiceProvider.overrideWithValue(FakePinService()),
            identityApiProvider.overrideWithValue(identityApi),
            secureStorageServiceProvider.overrideWithValue(storage),
            businessApiProvider.overrideWithValue(businessApi),
            tokenStoreProvider.overrideWithValue(TokenStore()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: createAppRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Splash re-checked onboarding-status and routed back here, not to
      // the dashboard.
      expect(find.byType(BusinessOnboardingScreen), findsOneWidget);

      // Step 1 — fill in the details (country defaults to TZ).
      await tester.enterText(
        find.byKey(const ValueKey('business-name')),
        'Mama Ngoja Eatery',
      );
      await tester.enterText(
        find.byKey(const ValueKey('business-city')),
        'Dar es Salaam',
      );
      await tester.enterText(
        find.byKey(const ValueKey('business-tax-id')),
        'TIN-123',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingContinue));
      await tester.pumpAndSettle();

      // Step 2 — the review shows what was entered.
      expect(find.text('Mama Ngoja Eatery'), findsOneWidget);
      expect(find.text('Dar es Salaam'), findsOneWidget);
      expect(find.text('Tanzania'), findsOneWidget);
      expect(find.text('TIN-123'), findsOneWidget);
      expect(find.text('Restaurant'), findsOneWidget);

      await tester.tap(find.text(AppStrings.onboardingCreateBusiness));
      await tester.pumpAndSettle();

      // POST /businesses was called with the correct payload.
      expect(businessApi.createCalls, hasLength(1));
      final request = businessApi.createCalls.single;
      expect(request.businessType, BusinessType.restaurant);
      expect(request.name, 'Mama Ngoja Eatery');
      expect(request.city, 'Dar es Salaam');
      expect(request.taxId, 'TIN-123');
      expect(request.countryCode, 'TZ');
      expect(request.timezone, 'Africa/Dar_es_Salaam');

      // completeOnboarding() promoted the state to a fully ready session,
      // so the router moved off onboarding onto the dashboard.
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      expect(container.read(authProvider), isA<SessionActive>());
      expect(container.read(authProvider), isNot(isA<OnboardingRequired>()));
      expect(find.byType(BusinessOnboardingScreen), findsNothing);
      expect(find.text('Dashboard'), findsWidgets);
    });

    testWidgets('business type is hardcoded to restaurant, not selectable',
        (tester) async {
      // The domain model only has restaurant for this app.
      expect(
        BusinessType.selfRegistrable.map((t) => t.apiValue),
        isNot(contains('platform_operator')),
      );
      expect(BusinessType.selfRegistrable, hasLength(1));
      expect(BusinessType.selfRegistrable.first, BusinessType.restaurant);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BusinessOnboardingScreen()),
        ),
      );
      await tester.pump();

      // Restaurant is not a selectable option in a business-type grid.
      expect(find.text('Supplier'), findsNothing);
      expect(find.text('Farmer'), findsNothing);
      expect(find.text('Distributor'), findsNothing);
      expect(find.textContaining('Platform'), findsNothing);
      expect(find.textContaining('platform_operator'), findsNothing);

      // Flush Riverpod's deferred provider-disposal timer before teardown
      // so the test framework doesn't fail on a pending timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('renders step 1 at phone and desktop breakpoints',
        (tester) async {
      Future<void> pumpAt(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: BusinessOnboardingScreen()),
          ),
        );
        await tester.pump();
      }

      // Phone — full-bleed single-column layout.
      await pumpAt(const Size(390, 844));
      expect(find.byKey(const ValueKey('business-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('business-city')), findsOneWidget);
      expect(find.text(AppStrings.onboardingContinue), findsOneWidget);

      // Desktop — centred card layout.
      await pumpAt(const Size(1280, 800));
      expect(find.byKey(const ValueKey('business-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('business-city')), findsOneWidget);
      expect(find.text(AppStrings.onboardingContinue), findsOneWidget);

      // Flush Riverpod's deferred provider-disposal timer before teardown
      // so the test framework doesn't fail on a pending timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets(
        'onboarding retry: when session scoping fails, user can retry and '
        'succeeds without creating a second business', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const userId = 'u_retry';
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: userId,
          phone: '+255700000002',
          displayName: 'Kofi',
          pin: '1234',
          active: true,
        );
      final storage = FakeSecureStorageService()..tokens[userId] = 'rt_1';
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
        // First onboarding-status: needsOnboarding=true (no business yet)
        // Second onboarding-status (after createBusiness): needsOnboarding=false
        needsOnboardingAfterBusinessCreation: false,
        businessIdAfterCreation: 'biz_retry',
        businessNameAfterCreation: 'Retry Business',
        // Fail the first switchBusinessContext attempt (simulate network blip)
        switchBusinessContextFailure: const Failure.auth(
          message: 'Context switch failed',
        ),
      );
      final businessApi = FakeBusinessApi();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localProfileRepositoryProvider.overrideWithValue(repository),
            pinServiceProvider.overrideWithValue(FakePinService()),
            identityApiProvider.overrideWithValue(identityApi),
            secureStorageServiceProvider.overrideWithValue(storage),
            businessApiProvider.overrideWithValue(businessApi),
            tokenStoreProvider.overrideWithValue(TokenStore()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: createAppRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1 — fill details
      await tester.enterText(
        find.byKey(const ValueKey('business-name')),
        'Retry Eatery',
      );
      await tester.enterText(
        find.byKey(const ValueKey('business-city')),
        'Accra',
      );
      await tester.enterText(
        find.byKey(const ValueKey('business-tax-id')),
        'TIN-999',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingContinue));
      await tester.pumpAndSettle();

      // Step 2 — first submit: createBusiness succeeds, but completeOnboarding
      // fails the switch. The screen shows the retry error and "Retry" button.
      await tester.tap(find.text(AppStrings.onboardingCreateBusiness));
      await tester.pumpAndSettle();

      // Business creation was called exactly once.
      expect(businessApi.createCalls, hasLength(1));

      // Error is shown (context-switch failure message) and button label changes to Retry.
      expect(find.textContaining('session could not be scoped'), findsOneWidget);
      expect(find.text(AppStrings.onboardingRetrySession), findsOneWidget);

      // Now make the second switchBusinessContext succeed by clearing the
      // injected failure. The fake is mutable so we can mutate it between taps.
      identityApi.switchBusinessContextFailure = null;

      // Tap Retry — this calls completeOnboarding again (no second createBusiness)
      await tester.tap(find.text(AppStrings.onboardingRetrySession));
      await tester.pumpAndSettle();

      // createBusiness was NOT called a second time (idempotent retry).
      expect(businessApi.createCalls, hasLength(1));
      // switchBusinessContext was called twice (failed once, succeeded on retry)
      expect(identityApi.switchBusinessContextCalls, equals(2));

      // Router moved to dashboard (sessionActive).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      expect(container.read(authProvider), isA<SessionActive>());
      expect(find.byType(BusinessOnboardingScreen), findsNothing);
      expect(find.text('Dashboard'), findsWidgets);
    });
  });
}