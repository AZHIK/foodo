import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_durations.dart';
import 'package:foodlink_business/core/error/failure.dart';
import 'package:foodlink_business/core/network/token_store.dart';
import 'package:foodlink_business/core/security/pin_service.dart';
import 'package:foodlink_business/core/storage/secure_storage_service.dart';
import 'package:foodlink_business/features/auth/application/auth_notifier.dart';
import 'package:foodlink_business/features/auth/data/identity_api.dart';
import 'package:foodlink_business/features/auth/data/local_profile_repository.dart';
import 'package:foodlink_business/features/auth/domain/auth_state.dart';

import '../../../helpers/fakes.dart';

void main() {
  const userId = 'user_1';
  const phone = '+233500000001';

  ProviderContainer createContainer({
    required FakeLocalProfileRepository repository,
    required FakePinService pinService,
    required FakeIdentityApi identityApi,
    required FakeSecureStorageService secureStorage,
  }) {
    final container = ProviderContainer(
      overrides: [
        localProfileRepositoryProvider.overrideWithValue(repository),
        pinServiceProvider.overrideWithValue(pinService),
        identityApiProvider.overrideWithValue(identityApi),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
        tokenStoreProvider.overrideWithValue(TokenStore()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> lockOutViaActivate(
    ProviderContainer container,
    AuthNotifier notifier,
  ) async {
    for (var i = 0; i < AppDurations.maxPinAttempts; i++) {
      await notifier.activateProfile(userId, pin: '0000');
    }
  }

  test('stores the issued access token after OTP verification', () async {
    final repository = FakeLocalProfileRepository();
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();
    final container = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final notifier = container.read(authProvider.notifier);

    await notifier.verifyOtp(phone, '654321');

    expect(
      container.read(tokenStoreProvider).accessToken,
      equals('header.payload.signature'),
    );
    expect(container.read(authProvider), isA<SettingPin>());
  });

  test('startOtpLogin returns to OTP sign-in keeping profiles', () async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(userId: userId, phone: phone, displayName: 'Ama', pin: '1234');
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();
    final container = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final notifier = container.read(authProvider.notifier);

    await notifier.initialize();
    expect(container.read(authProvider), isA<ProfilesAvailable>());

    notifier.startOtpLogin();

    expect(container.read(authProvider), isA<Unauthenticated>());
    expect(container.read(tokenStoreProvider).accessToken, isNull);
    expect(await repository.listProfiles(), isNotEmpty);
  });

  test('locks out after 5 wrong PINs; the 6th is rejected without Argon2id',
      () async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(userId: userId, phone: phone, displayName: 'Ama', pin: '1234');
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();
    final container = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final notifier = container.read(authProvider.notifier);

    await notifier.initialize();
    expect(container.read(authProvider), isA<ProfilesAvailable>());

    await lockOutViaActivate(container, notifier);

    expect(container.read(authProvider), isA<PinLockedOut>());
    expect(pinService.verifyPinCalls, equals(AppDurations.maxPinAttempts));

    final profile = repository.profiles[userId]!;
    expect(profile.pinAttemptCount, equals(AppDurations.maxPinAttempts));
    expect(profile.pinLockedUntil, isNotNull);

    final rejected = await notifier.activateProfile(userId, pin: '1234');
    expect(rejected, isA<Failure>());
    expect(container.read(authProvider), isA<PinLockedOut>());
    expect(pinService.verifyPinCalls, equals(AppDurations.maxPinAttempts));
  });

  test('a correct PIN before the threshold succeeds and resets the counter',
      () async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(
        userId: userId,
        phone: phone,
        displayName: 'Ama',
        pin: '1234',
        pinAttemptCount: 2,
      );
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();
    final container = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final notifier = container.read(authProvider.notifier);

    await notifier.initialize();

    await notifier.activateProfile(userId, pin: '0000');
    await notifier.activateProfile(userId, pin: '0000');
    expect(repository.profiles[userId]!.pinAttemptCount, equals(4));

    final result = await notifier.activateProfile(userId, pin: '1234');
    expect(result, isNull);
    expect(container.read(authProvider), isA<SessionActive>());
    expect(repository.profiles[userId]!.pinAttemptCount, equals(0));
    expect(repository.profiles[userId]!.pinLockedUntil, isNull);
  });

  test('lockout persists across a simulated app restart (fresh notifier)',
      () async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(userId: userId, phone: phone, displayName: 'Ama', pin: '1234');
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();

    final firstContainer = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final firstNotifier = firstContainer.read(authProvider.notifier);

    await firstNotifier.initialize();
    await firstNotifier.activateProfile(userId, pin: '1234');
    expect(firstContainer.read(authProvider), isA<SessionActive>());

    for (var i = 0; i < AppDurations.maxPinAttempts; i++) {
      await firstNotifier.unlock(pin: '0000');
    }
    expect(firstContainer.read(authProvider), isA<PinLockedOut>());

    final secondContainer = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final secondNotifier = secondContainer.read(authProvider.notifier);

    await secondNotifier.initialize();
    expect(secondContainer.read(authProvider), isA<PinLockedOut>());
    final profile = repository.profiles[userId]!;
    expect(profile.pinLockedUntil, isNotNull);
  });

  test(
      'OTP re-verification for a locked-out profile clears lockout and '
      'routes to the set-new-PIN flow', () async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(userId: userId, phone: phone, displayName: 'Ama', pin: '1234');
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();
    final container = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final notifier = container.read(authProvider.notifier);

    await notifier.initialize();
    await lockOutViaActivate(container, notifier);
    expect(container.read(authProvider), isA<PinLockedOut>());

    final startResult = await notifier.startLockoutResolution(userId);
    expect(startResult, isNull);
    expect(identityApi.requestOtpCalls, equals(1));
    expect(container.read(authProvider), isA<OtpPending>());

    final completeResult =
        await notifier.completeLockoutResolution(phone, '654321');
    expect(completeResult, isNull);
    expect(identityApi.verifyOtpCalls, equals(1));

    final profile = repository.profiles[userId]!;
    expect(profile.pinAttemptCount, equals(0));
    expect(profile.pinLockedUntil, isNull);

    final state = container.read(authProvider);
    expect(state, isA<SettingPin>());
    final settingPin = state as SettingPin;
    expect(settingPin.userId, equals(userId));
    expect(settingPin.phone, equals(phone));
    expect(settingPin.refreshToken, equals('rt_1'));
  });

  test('the new PIN set after lockout resolution works for later unlocks',
      () async {
    final repository = FakeLocalProfileRepository()
      ..seedProfile(userId: userId, phone: phone, displayName: 'Ama', pin: '1234');
    final pinService = FakePinService();
    final identityApi =
        FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321');
    final storage = FakeSecureStorageService();
    final container = createContainer(
      repository: repository,
      pinService: pinService,
      identityApi: identityApi,
      secureStorage: storage,
    );
    final notifier = container.read(authProvider.notifier);

    await notifier.initialize();
    await lockOutViaActivate(container, notifier);

    await notifier.startLockoutResolution(userId);
    await notifier.completeLockoutResolution(phone, '654321');

    final setResult = await notifier.setPin(
      phone: phone,
      userId: userId,
      refreshToken: 'rt_new',
      pin: '9876',
      displayName: null,
    );
    expect(setResult, isNull);
    expect(container.read(authProvider), isA<SessionActive>());
    expect(storage.tokens[userId], equals('rt_new'));

    final profile = repository.profiles[userId]!;
    expect(profile.pinHash, equals('argon2id:9876'));
    expect(profile.pinAttemptCount, equals(0));
    expect(profile.pinLockedUntil, isNull);
    expect(profile.displayName, equals('Ama'));

    notifier.lock();
    expect(
      container.read(authProvider),
      isA<SessionActive>()
          .having((s) => s.locked, 'locked', isTrue),
    );

    final oldPinResult = await notifier.unlock(pin: '1234');
    expect(oldPinResult, isA<Failure>());

    final newPinResult = await notifier.unlock(pin: '9876');
    expect(newPinResult, isNull);
    final unlocked = container.read(authProvider) as SessionActive;
    expect(unlocked.locked, isFalse);
  });

  group('removeFromDevice', () {
    test('is rejected when there is no active session and deletes nothing',
        () async {
      final repository = FakeLocalProfileRepository()
        ..seedProfile(userId: userId, phone: phone, displayName: 'Ama', pin: '1234');
      final container = createContainer(
        repository: repository,
        pinService: FakePinService(),
        identityApi:
            FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321'),
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.initialize();
      expect(container.read(authProvider), isA<ProfilesAvailable>());

      final result = await notifier.removeFromDevice(pin: '1234');

      expect(result, isA<Failure>());
      expect(await repository.listProfiles(), isNotEmpty);
    });

    test('removes only the ACTIVE profile with the correct PIN', () async {
      const otherUserId = 'user_2';
      const otherPhone = '+233500000002';
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: userId,
          phone: phone,
          displayName: 'Ama',
          pin: '1234',
        )
        ..seedProfile(
          userId: otherUserId,
          phone: otherPhone,
          displayName: 'Kofi',
          pin: '5678',
        );
      final container = createContainer(
        repository: repository,
        pinService: FakePinService(),
        identityApi:
            FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321'),
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.initialize();
      final result = await notifier.activateProfile(userId, pin: '1234');
      expect(result, isNull);
      expect(container.read(authProvider), isA<SessionActive>());

      final removeResult = await notifier.removeFromDevice(pin: '1234');

      expect(removeResult, isNull);
      final remaining = await repository.listProfiles();
      expect(remaining.map((p) => p.userId), isNot(contains(userId)));
      expect(remaining.map((p) => p.userId), contains(otherUserId));
      expect(container.read(authProvider), isA<ProfilesAvailable>());
    });

    test('wrong PIN blocks removal and deletes nothing', () async {
      final repository = FakeLocalProfileRepository()
        ..seedProfile(
          userId: userId,
          phone: phone,
          displayName: 'Ama',
          pin: '1234',
          active: true,
        );
      final container = createContainer(
        repository: repository,
        pinService: FakePinService(),
        identityApi:
            FakeIdentityApi(userId: userId, refreshToken: 'rt_1', validCode: '654321'),
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.initialize();
      expect(container.read(authProvider), isA<SessionActive>());

      final result = await notifier.removeFromDevice(pin: '9999');

      expect(result, isA<Failure>());
      expect(await repository.listProfiles(), hasLength(1));
      expect(await repository.profileById(userId), isNotNull);
    });
  });
}
