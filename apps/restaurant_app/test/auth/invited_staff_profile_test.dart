/// Reproduction: invited staff OTP -> name/email -> local profile row.
///
/// Drives the real provider flow an invited staff member goes through and
/// asserts the `LocalUserProfiles` row is created at the complete-profile
/// step and filled in at the set-PIN step.
library;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/models/session.dart';
import 'package:restaurant_pos/providers/auth_provider.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/session_provider.dart';
import 'package:restaurant_pos/utils/pin_hasher.dart';

import '../test_helpers/fake_identity_backend.dart';
import '../test_helpers/test_container.dart';

/// In-memory secure storage (TokenStorage has no Riverpod seam).
void _mockSecureStorage() {
  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
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
      default:
        return null;
    }
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding.instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
}

ProviderContainer _containerWithBackend(FakeIdentityBackendState backendState) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = FakeIdentityAdapter(backendState);
  return newTestContainer(extraOverrides: [
    identityServiceDioProvider.overrideWithValue(dio),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invited staff profile is saved locally after OTP + name/email',
      () async {
    _mockSecureStorage();

    // Invited staff: account exists, has a business, but no name on file yet.
    final backendState = FakeIdentityBackendState()
      ..needsOnboarding = false
      ..businessId = 'biz-1'
      ..businessName = 'Test Biz'
      ..fullName = '';
    final container = _containerWithBackend(backendState);

    // 1. OTP login.
    await container
        .read(sessionProvider.notifier)
        .requestOtp('+255700000001');
    await container
        .read(sessionProvider.notifier)
        .completeOtpLogin(fakeOtpCode);

    final userId = container.read(authProvider).userId;
    expect(userId, isNotNull);

    // 2. Name + email.
    await container.read(authProvider.notifier).completeProfile(
          fullName: 'Invited Staff',
          email: 'staff@example.com',
        );

    final repo = container.read(localProfileRepositoryProvider);
    final afterProfile = await repo.getProfile(userId!);
    expect(afterProfile, isNotNull,
        reason: 'complete-profile must create the local profile row');
    expect(afterProfile!.displayName, 'Invited Staff');

    // 3. Set PIN fills in the row.
    await container.read(sessionProvider.notifier).setPin('246810');
    final afterPin = await repo.getProfile(userId);
    expect(afterPin!.pinHash, isNotEmpty);
    expect(afterPin.displayName, 'Invited Staff');
  });

  group('second user on the same terminal (after end shift)', () {
    test('a newcomer clears the previous user\'s stale PIN and gets Set PIN',
        () async {
      _mockSecureStorage();
      final container =
          _containerWithBackend(FakeIdentityBackendState());

      // User 1's session is still in memory (end shift only locks).
      container.read(sessionProvider.notifier).state = const SessionState(
        savedProfileIds: ['user-1'],
        activeStaffId: 'user-1',
        isLoggedIn: true,
        pin: 'user-1-pin',
        isUnlocked: false,
        hasCompletedOnboarding: true,
        bootstrapped: true,
      );

      // User 2 (fake-user-id) has no local row on this terminal.
      await container
          .read(sessionProvider.notifier)
          .requestOtp('+255700000002');
      await container
          .read(sessionProvider.notifier)
          .completeOtpLogin(fakeOtpCode);

      final session = container.read(sessionProvider);
      expect(session.activeStaffId, 'fake-user-id');
      expect(session.hasPin, isFalse,
          reason: 'stale PIN of user 1 must not leak to user 2');
      expect(session.entryRoute, '/auth/set-pin');

      // Set PIN then creates the local row for user 2.
      await container.read(sessionProvider.notifier).setPin('246810');
      final repo = container.read(localProfileRepositoryProvider);
      final row = await repo.getProfile('fake-user-id');
      expect(row, isNotNull);
      expect(row!.pinHash, isNotEmpty);
    });

    test('a returning user keeps their stored PIN hash', () async {
      _mockSecureStorage();
      final container =
          _containerWithBackend(FakeIdentityBackendState());

      // Returning user already has a row with a PIN from a previous sign-in.
      final repo = container.read(localProfileRepositoryProvider);
      final now = DateTime.now();
      await repo.upsertProfile(LocalUserProfilesCompanion.insert(
        id: 'fake-user-id',
        displayName: 'Returning Staff',
        pinHash: 'stored-hash',
        pinSalt: 'stored-salt',
        createdAt: now,
        updatedAt: now,
      ));

      container.read(sessionProvider.notifier).state = const SessionState(
        savedProfileIds: ['user-1'],
        activeStaffId: 'user-1',
        isLoggedIn: true,
        pin: 'user-1-pin',
        isUnlocked: false,
        hasCompletedOnboarding: true,
        bootstrapped: true,
      );

      await container
          .read(sessionProvider.notifier)
          .requestOtp('+255700000002');
      await container
          .read(sessionProvider.notifier)
          .completeOtpLogin(fakeOtpCode);

      final session = container.read(sessionProvider);
      expect(session.activeStaffId, 'fake-user-id');
      expect(session.hasPin, isTrue);
    });
  });

  group('logout deactivation', () {
    test('logout deactivates the row and hides it; re-login reactivates',
        () async {
      _mockSecureStorage();
      final container =
          _containerWithBackend(FakeIdentityBackendState());

      // Active signed-in user with a local row.
      final repo = container.read(localProfileRepositoryProvider);
      final now = DateTime.now();
      await repo.upsertProfile(LocalUserProfilesCompanion.insert(
        id: 'fake-user-id',
        displayName: 'Staff',
        pinHash: 'h',
        pinSalt: 's',
        createdAt: now,
        updatedAt: now,
      ));
      container.read(sessionProvider.notifier).state = const SessionState(
        savedProfileIds: ['fake-user-id'],
        activeStaffId: 'fake-user-id',
        isLoggedIn: true,
        pin: '123456',
        isUnlocked: true,
        hasCompletedOnboarding: true,
        bootstrapped: true,
      );

      await container.read(sessionProvider.notifier).logout();

      // Row kept (PIN/role/permissions intact) but deactivated and hidden.
      var row = await repo.getProfile('fake-user-id');
      expect(row!.isDeactivated, isTrue);
      expect(row.pinHash, 'h');
      expect(await repo.activeProfiles(), isEmpty);
      expect(
        container.read(sessionProvider).savedProfileIds,
        isEmpty,
      );
      expect(container.read(sessionProvider).entryRoute, '/auth/login');

      // Same user logs in again via OTP.
      await container
          .read(sessionProvider.notifier)
          .requestOtp('+255700000001');
      await container
          .read(sessionProvider.notifier)
          .completeOtpLogin(fakeOtpCode);

      row = await repo.getProfile('fake-user-id');
      expect(row!.isDeactivated, isFalse);
      expect(
        container.read(sessionProvider).savedProfileIds,
        contains('fake-user-id'),
      );
    });

    test('PIN unlock refuses a deactivated profile even with the right PIN',
        () async {
      _mockSecureStorage();
      final container =
          _containerWithBackend(FakeIdentityBackendState());

      const pin = '246810';
      final salt = PinHasher.generateSalt();
      final repo = container.read(localProfileRepositoryProvider);
      final now = DateTime.now();
      await repo.upsertProfile(LocalUserProfilesCompanion.insert(
        id: 'fake-user-id',
        displayName: 'Staff',
        pinHash: PinHasher.hash(pin, salt),
        pinSalt: salt,
        createdAt: now,
        updatedAt: now,
        isDeactivated: const Value(false),
      ));
      await repo.setDeactivated('fake-user-id', true);

      container.read(sessionProvider.notifier).state = const SessionState(
        savedProfileIds: ['fake-user-id'],
        activeStaffId: 'fake-user-id',
        isLoggedIn: true,
        bootstrapped: true,
      );

      expect(await container.read(sessionProvider.notifier).submitPin(pin),
          isFalse);
      expect(container.read(sessionProvider).isUnlocked, isFalse);
    });
  });
}
