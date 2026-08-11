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

    final accessToken = container.read(tokenStoreProvider).accessToken;
    expect(accessToken, isNotNull);
    // The OTP-issued token is unscoped (no active_business_id).
    final claims = decodeJwtPayload(accessToken!);
    expect(claims['active_business_id'], isNull);
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
    final identityApi = FakeIdentityApi(
      userId: userId,
      refreshToken: 'rt_1',
      validCode: '654321',
      needsOnboarding: false,
      businessId: 'biz_lockout',
      businessName: 'Lockout Business',
    );
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
    // The rotated refresh token from the context switch is what's stored.
    expect(storage.tokens[userId], equals('rt_rotated_rt_1'));

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

  group('onboarding', () {
    test(
        'a self-registered user (no business role) transitions to '
        'onboardingRequired after setPin', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
      );
      final storage = FakeSecureStorageService();
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: storage,
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      final result = await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );

      expect(result, isNull);
      expect(identityApi.onboardingStatusCalls, equals(1));
      expect(container.read(authProvider), isA<OnboardingRequired>());
      expect(container.read(authProvider), isNot(isA<SessionActive>()));
      expect(storage.tokens[userId], equals('rt_1'));
      expect(await repository.listProfiles(), hasLength(1));
    });

    test('completeOnboarding promotes onboardingRequired to sessionActive',
        () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
        businessId: 'biz_1',
        businessName: 'Test Business',
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );
      expect(container.read(authProvider), isA<OnboardingRequired>());

      await notifier.completeOnboarding();

      final state = container.read(authProvider);
      expect(state, isA<SessionActive>());
      expect((state as SessionActive).profile.userId, equals(userId));
    });

    test(
        'an invited staff member skips onboarding entirely: onboarding-status '
        'returns false and setPin lands directly on sessionActive', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      // needsOnboarding defaults to false — the invited-staff case.
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: false,
        businessId: 'biz_1',
        businessName: 'Test Business',
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      final result = await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );

      expect(result, isNull);
      // The status endpoint WAS consulted (so the skip is proven by the
      // server's answer, not assumed) and yet the user lands on the
      // dashboard-ready state, never onboarding.
      expect(identityApi.onboardingStatusCalls, equals(1));
      expect(container.read(authProvider), isA<SessionActive>());
      expect(container.read(authProvider), isNot(isA<OnboardingRequired>()));
    });

    test(
        'a mid-onboarding app restart re-checks onboarding-status on '
        'initialize() and returns to onboardingRequired, not sessionActive',
        () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
        needsOnboardingAfterBusinessCreation: true,
      );
      final storage = FakeSecureStorageService();

      // First launch: set a PIN, land in onboardingRequired.
      final firstContainer = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: storage,
      );
      final firstNotifier = firstContainer.read(authProvider.notifier);
      await firstNotifier.verifyOtp(phone, '654321');
      await firstNotifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );
      expect(firstContainer.read(authProvider), isA<OnboardingRequired>());

      // "Kill" the app: a fresh container shares the same persistence
      // (profile row + refresh token) but starts from scratch.
      final secondContainer = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: storage,
      );
      final secondNotifier = secondContainer.read(authProvider.notifier);

      await secondNotifier.initialize();

      // The server is re-checked (not a locally cached flag)...
      expect(identityApi.onboardingStatusCalls, greaterThanOrEqualTo(2));
      expect(identityApi.refreshAccessTokenCalls, equals(1));
      // ...the rotated refresh token is persisted for the next launch...
      expect(storage.tokens[userId], equals('rt_rotated_rt_1'));
      // ...and the user is routed back to the onboarding flow, not dumped
      // into an ambiguous ready state.
      expect(secondContainer.read(authProvider), isA<OnboardingRequired>());
      expect(secondContainer.read(authProvider), isNot(isA<SessionActive>()));
    });
  });

  group('token scoping', () {
    test(
        'onboarding owner: completeOnboarding calls switchBusinessContext '
        'and stores a scoped token', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
        businessId: 'biz_1',
        businessName: 'Test Business',
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );
      expect(container.read(authProvider), isA<OnboardingRequired>());

      final failure = await notifier.completeOnboarding();
      expect(failure, isNull);

      final state = container.read(authProvider);
      expect(state, isA<SessionActive>());

      // The access token is now business-scoped.
      final accessToken = container.read(tokenStoreProvider).accessToken;
      expect(accessToken, isNotNull);
      final claims = decodeJwtPayload(accessToken!);
      expect(claims['active_business_id'], equals('biz_1'));
      expect(claims['roles'], contains('owner'));
      expect(claims['permissions'], contains('business.read'));
      expect(identityApi.switchBusinessContextCalls, equals(1));
    });

    test(
        'invited staff: setPin calls switchBusinessContext and stores a scoped '
        'token', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: false,
        businessId: 'biz_2',
        businessName: 'Staff Business',
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      final result = await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );

      expect(result, isNull);
      expect(container.read(authProvider), isA<SessionActive>());

      // The access token is now business-scoped.
      final accessToken = container.read(tokenStoreProvider).accessToken;
      expect(accessToken, isNotNull);
      final claims = decodeJwtPayload(accessToken!);
      expect(claims['active_business_id'], equals('biz_2'));
      expect(claims['roles'], contains('owner'));
      expect(identityApi.switchBusinessContextCalls, equals(1));
    });

    test(
        'invited staff: setPin switch failure leaves user retryable '
        '(does not advance to sessionActive)', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: false,
        businessId: 'biz_3',
        businessName: 'Staff Business',
        switchBusinessContextFailure: const Failure.network(
          message: 'Context switch failed',
        ),
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      final result = await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );

      // A Failure is returned, the user can retry.
      expect(result, isA<Failure>());
      // State did NOT advance to sessionActive.
      expect(container.read(authProvider), isNot(isA<SessionActive>()));
      // The unscoped token was cleared so a retry doesn't silently use it.
      expect(container.read(tokenStoreProvider).accessToken, isNull);
    });

    test(
        'onboarding owner: completeOnboarding switch failure leaves user '
        'retryable (stays in onboardingRequired)', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: true,
        businessId: 'biz_4',
        businessName: 'Test Business',
        switchBusinessContextFailure: const Failure.network(
          message: 'Context switch failed',
        ),
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );
      expect(container.read(authProvider), isA<OnboardingRequired>());

      final failure = await notifier.completeOnboarding();
      expect(failure, isA<Failure>());
      // State stays onboardingRequired for retry.
      expect(container.read(authProvider), isA<OnboardingRequired>());
      // The unscoped token was cleared so a retry doesn't silently use it.
      expect(container.read(tokenStoreProvider).accessToken, isNull);
    });

    test(
        'cold start with persisted profile + refresh token re-derives unscoped '
        'token, then switches to scoped token in _resolveBootSession', () async {
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_persisted',
        validCode: '654321',
        needsOnboarding: false,
        businessId: 'biz_cold',
        businessName: 'Cold Start Business',
      );
      final storage = FakeSecureStorageService()
        ..tokens[userId] = 'rt_persisted';
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: storage,
      );
      final notifier = container.read(authProvider.notifier);

      // Seed an active profile with an activeBusinessId so initialize takes
      // the "existing session" path and reaches _resolveBootSession.
      await repository.upsertProfile(
        userId: userId,
        phone: phone,
        displayName: 'Ama',
        pinHash: 'argon2id:1234',
        activeBusinessId: 'biz_cold',
      );

      await notifier.initialize();

      // State is sessionActive.
      expect(container.read(authProvider), isA<SessionActive>());

      // Refresh was called once (to get unscoped token from refresh token).
      expect(identityApi.refreshAccessTokenCalls, equals(1));
      // Then switchBusinessContext was called to scope it.
      expect(identityApi.switchBusinessContextCalls, equals(1));

      // The access token is now business-scoped.
      final accessToken = container.read(tokenStoreProvider).accessToken;
      expect(accessToken, isNotNull);
      final claims = decodeJwtPayload(accessToken!);
      expect(claims['active_business_id'], equals('biz_cold'));
      expect(claims['roles'], contains('owner'));
      // The rotated refresh token from the switch is persisted.
      expect(storage.tokens[userId], equals('rt_rotated_rt_persisted'));
    });

    test(
        'mock business-scoped endpoint succeeds when called with scoped token '
        '(regression: 403 on first business call)', () async {
      // This simulates a real business-scoped call (e.g., GET /businesses/{id})
      // that would 403 with an unscoped token but succeeds with a scoped one.
      final repository = FakeLocalProfileRepository();
      final pinService = FakePinService();
      final identityApi = FakeIdentityApi(
        userId: userId,
        refreshToken: 'rt_1',
        validCode: '654321',
        needsOnboarding: false,
        businessId: 'biz_regression',
        businessName: 'Regression Business',
      );
      final container = createContainer(
        repository: repository,
        pinService: pinService,
        identityApi: identityApi,
        secureStorage: FakeSecureStorageService(),
      );
      final notifier = container.read(authProvider.notifier);

      await notifier.verifyOtp(phone, '654321');
      await notifier.setPin(
        phone: phone,
        userId: userId,
        refreshToken: 'rt_1',
        pin: '1234',
      );

      // At this point setPin succeeded and scoped the token.
      final accessToken = container.read(tokenStoreProvider).accessToken!;
      final claims = decodeJwtPayload(accessToken);

      // Simulate a business-scoped endpoint that checks the active_business_id
      // claim (as the real backend does). This would 403 if the claim were
      // missing/null — the bug we fixed.
      expect(claims['active_business_id'], equals('biz_regression'));
      expect(claims['permissions'], contains('business.read'));
    });
  });
}
