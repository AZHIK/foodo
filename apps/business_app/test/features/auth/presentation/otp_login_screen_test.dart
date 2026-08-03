import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_strings.dart';
import 'package:foodlink_business/core/sync/connectivity_service.dart';
import 'package:foodlink_business/features/auth/presentation/screens/otp_login_screen.dart';

import '../../../helpers/fakes.dart';

void main() {
  ProviderContainer containerWithConnectivity({required bool online}) {
    final base = createAuthTestContainer(
      repository: FakeLocalProfileRepository(),
      pinService: FakePinService(),
      identityApi: FakeIdentityApi(
        userId: 'u1',
        refreshToken: 'rt',
        validCode: '654321',
      ),
      secureStorage: FakeSecureStorageService(),
    );
    final container = ProviderContainer(
      parent: base,
      overrides: [
        connectivityProvider.overrideWith((ref) => Stream.value(online)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('shows an offline banner when there is no connectivity',
      (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: containerWithConnectivity(online: false),
        child: const MaterialApp(home: OtpLoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.offline), findsOneWidget);
  });

  testWidgets('does not show an offline banner when online', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: containerWithConnectivity(online: true),
        child: const MaterialApp(home: OtpLoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.offline), findsNothing);
  });
}
