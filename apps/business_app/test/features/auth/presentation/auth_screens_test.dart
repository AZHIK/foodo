import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_strings.dart';
import 'package:foodlink_business/features/auth/application/auth_notifier.dart';
import 'package:foodlink_business/features/auth/presentation/screens/profile_picker_screen.dart';
import 'package:foodlink_business/features/auth/presentation/screens/pin_unlock_screen.dart';
import 'package:foodlink_business/shared/widgets/widgets.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('ProfilePickerScreen', () {
    testWidgets('shows all available profiles', (tester) async {
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: 'u1',
          phone: '+233500000001',
          displayName: 'Ama',
          pin: '1234',
        )
        ..seedProfile(
          userId: 'u2',
          phone: '+233500000002',
          displayName: 'Kofi',
          pin: '5678',
        );
      final container = createAuthTestContainer(
        repository: repository,
        pinService: FakePinService(),
        identityApi: FakeIdentityApi(
          userId: 'u1',
          refreshToken: 'rt',
          validCode: '654321',
        ),
        secureStorage: FakeSecureStorageService(),
      );
      await container.read(authProvider.notifier).initialize();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfilePickerScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Ama'), findsOneWidget);
      expect(find.text('Kofi'), findsOneWidget);
      expect(find.text(AppStrings.profilePickerSignIn), findsOneWidget);
    });
  });

  group('PinUnlockScreen', () {
    testWidgets('shows the lockout UI when the selected profile is locked',
        (tester) async {
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: 'u1',
          phone: '+233500000001',
          displayName: 'Ama',
          pin: '1234',
          pinLockedUntil: DateTime.now().add(const Duration(days: 1)),
        );
      final container = createAuthTestContainer(
        repository: repository,
        pinService: FakePinService(),
        identityApi: FakeIdentityApi(
          userId: 'u1',
          refreshToken: 'rt',
          validCode: '654321',
        ),
        secureStorage: FakeSecureStorageService(),
      );
      await container.read(authProvider.notifier).initialize();
      container.read(authProvider.notifier).selectProfileForUnlock('u1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PinUnlockScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.pinLockedOutTitle), findsWidgets);
      expect(find.text(AppStrings.pinLockedOutMessage), findsOneWidget);
      expect(find.text(AppStrings.pinLockedOutVerifyPhone), findsOneWidget);
    });

    testWidgets('shows PIN entry when the active session is re-locked',
        (tester) async {
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: 'u1',
          phone: '+233500000001',
          displayName: 'Ama',
          pin: '1234',
          active: true,
        );
      final container = createAuthTestContainer(
        repository: repository,
        pinService: FakePinService(),
        identityApi: FakeIdentityApi(
          userId: 'u1',
          refreshToken: 'rt',
          validCode: '654321',
        ),
        secureStorage: FakeSecureStorageService(),
      );
      await container.read(authProvider.notifier).initialize();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PinUnlockScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.pinUnlockTitle), findsWidgets);
      expect(find.text(AppStrings.pinUnlockSubtitle), findsOneWidget);
      // PIN entry is the keypad (dot indicator + digits), not a TextField.
      expect(find.byType(AppPinPad), findsOneWidget);
    });
  });
}
