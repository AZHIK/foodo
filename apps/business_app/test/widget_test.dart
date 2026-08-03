import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/app/router/app_router.dart';
import 'package:foodlink_business/app/theme/app_theme.dart';
import 'package:foodlink_business/core/security/pin_service.dart';
import 'package:foodlink_business/core/storage/secure_storage_service.dart';
import 'package:foodlink_business/features/auth/data/identity_api.dart';
import 'package:foodlink_business/features/auth/data/local_profile_repository.dart';
import 'package:foodlink_business/features/auth/presentation/screens/otp_login_screen.dart';
import 'package:foodlink_business/features/auth/presentation/screens/profile_picker_screen.dart';

import 'helpers/fakes.dart';

void main() {
  Widget buildApp({
    required FakeLocalProfileRepository repository,
    required FakePinService pinService,
    required FakeIdentityApi identityApi,
    required FakeSecureStorageService secureStorage,
  }) {
    return ProviderScope(
      overrides: [
        localProfileRepositoryProvider.overrideWithValue(repository),
        pinServiceProvider.overrideWithValue(pinService),
        identityApiProvider.overrideWithValue(identityApi),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: createAppRouter(),
      ),
    );
  }

  testWidgets('splash shows branding then routes to login when no profiles exist',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        repository: FakeLocalProfileRepository(),
        pinService: FakePinService(),
        identityApi:
            FakeIdentityApi(userId: 'u1', refreshToken: 'rt', validCode: '654321'),
        secureStorage: FakeSecureStorageService(),
      ),
    );

    // First frame shows the splash branding and loading indicator.
    expect(find.text('FoodLink Business'), findsOneWidget);
    expect(find.text('Powering African food businesses'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // After initialize() completes the splash redirects to the OTP login.
    await tester.pumpAndSettle();
    expect(find.byType(OtpLoginScreen), findsOneWidget);
  });

  testWidgets('splash routes to the profile picker when profiles exist',
      (tester) async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(
        userId: 'u1',
        phone: '+233500000001',
        displayName: 'Ama',
        pin: '1234',
      );

    await tester.pumpWidget(
      buildApp(
        repository: repository,
        pinService: FakePinService(),
        identityApi:
            FakeIdentityApi(userId: 'u1', refreshToken: 'rt', validCode: '654321'),
        secureStorage: FakeSecureStorageService(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ProfilePickerScreen), findsOneWidget);
    expect(find.text('Ama'), findsOneWidget);
  });
}
