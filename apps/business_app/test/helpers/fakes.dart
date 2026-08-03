import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/error/failure.dart';
import 'package:foodlink_business/core/network/token_store.dart';
import 'package:foodlink_business/core/security/pin_service.dart';
import 'package:foodlink_business/core/storage/app_database.dart';
import 'package:foodlink_business/core/storage/secure_storage_service.dart';
import 'package:foodlink_business/features/auth/data/identity_api.dart';
import 'package:foodlink_business/features/auth/data/local_profile_repository.dart';

/// Shared fakes used across auth unit and widget tests.
///
/// The fake PIN service keys hashes as `argon2id:<pin>` and verifies by
/// equality, mirroring the contract the real Argon2id service implements.

class FakePinService extends PinService {
  String storedHash = '';
  int verifyPinCalls = 0;

  @override
  Future<String> hashPin(String pin) async {
    storedHash = 'argon2id:$pin';
    return storedHash;
  }

  @override
  Future<bool> verifyPin(String pin, String pinHash) async {
    verifyPinCalls++;
    return 'argon2id:$pin' == pinHash;
  }
}

class FakeIdentityApi implements IdentityApi {
  FakeIdentityApi({
    required this.userId,
    required this.refreshToken,
    required this.validCode,
  });

  final String userId;
  final String refreshToken;
  final String validCode;
  int requestOtpCalls = 0;
  int verifyOtpCalls = 0;

  @override
  Future<void> requestOtp(String phone) async {
    requestOtpCalls++;
  }

  @override
  Future<OtpVerificationResult> verifyOtp(String phone, String code) async {
    verifyOtpCalls++;
    if (code != validCode) {
      throw const Failure.validation(message: 'Invalid code.');
    }
    return OtpVerificationResult(
      userId: userId,
      accessToken: 'header.payload.signature',
      refreshToken: refreshToken,
    );
  }
}

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> tokens = {};

  @override
  Future<void> saveRefreshToken({
    required String userId,
    required String token,
  }) async {
    tokens[userId] = token;
  }

  @override
  Future<String?> readRefreshToken(String userId) async => tokens[userId];

  @override
  Future<void> deleteRefreshToken(String userId) async {
    tokens.remove(userId);
  }
}

class FakeLocalProfileRepository implements LocalProfileRepository {
  final Map<String, LocalUserProfile> profiles = {};

  void seedProfile({
    required String userId,
    required String phone,
    required String displayName,
    required String pin,
    bool active = false,
    int pinAttemptCount = 0,
    DateTime? pinLockedUntil,
  }) {
    profiles[userId] = LocalUserProfile(
      userId: userId,
      phone: phone,
      displayName: displayName,
      pinHash: 'argon2id:$pin',
      activeBusinessId: null,
      lastLoginAt: DateTime.now(),
      isCurrentlyActive: active,
      pinAttemptCount: pinAttemptCount,
      pinLockedUntil: pinLockedUntil,
    );
  }

  @override
  Future<List<LocalUserProfile>> listProfiles() async =>
      profiles.values.toList();

  @override
  Future<LocalUserProfile?> profileById(String userId) async =>
      profiles[userId];

  @override
  Future<LocalUserProfile> activeProfile() async {
    return profiles.values.firstWhere(
      (p) => p.isCurrentlyActive,
      orElse: () => throw StateError('No active profile.'),
    );
  }

  @override
  Future<void> upsertProfile({
    required String userId,
    required String phone,
    required String displayName,
    required String pinHash,
    String? activeBusinessId,
  }) async {
    _deactivateAll();
    final existing = profiles[userId];
    profiles[userId] = LocalUserProfile(
      userId: userId,
      phone: phone,
      displayName: displayName,
      pinHash: pinHash,
      activeBusinessId: activeBusinessId,
      lastLoginAt: DateTime.now(),
      isCurrentlyActive: true,
      pinAttemptCount: existing?.pinAttemptCount ?? 0,
      pinLockedUntil: existing?.pinLockedUntil,
    );
  }

  @override
  Future<void> activate(String userId) async {
    _deactivateAll();
    profiles[userId] = profiles[userId]!.copyWith(
      isCurrentlyActive: true,
      lastLoginAt: DateTime.now(),
    );
  }

  @override
  Future<void> endShift() async {
    _deactivateAll();
  }

  @override
  Future<void> removeProfile(String userId) async {
    profiles.remove(userId);
  }

  @override
  Future<void> incrementPinAttempts(String userId, int count) async {
    profiles[userId] = profiles[userId]!.copyWith(pinAttemptCount: count);
  }

  @override
  Future<void> lockProfile(
    String userId, {
    required DateTime lockedUntil,
  }) async {
    profiles[userId] = profiles[userId]!.copyWith(
      pinLockedUntil: Value(lockedUntil),
    );
  }

  @override
  Future<void> resetPinAttempts(String userId) async {
    profiles[userId] = profiles[userId]!.copyWith(pinAttemptCount: 0);
  }

  @override
  Future<void> clearLockout(String userId) async {
    profiles[userId] = profiles[userId]!.copyWith(
      pinAttemptCount: 0,
      pinLockedUntil: const Value(null),
    );
  }

  void _deactivateAll() {
    for (final key in profiles.keys.toList()) {
      if (profiles[key]!.isCurrentlyActive) {
        profiles[key] = profiles[key]!.copyWith(isCurrentlyActive: false);
      }
    }
  }
}

/// Builds a [ProviderContainer] overriding every auth dependency with the
/// supplied fakes. Disposes the container on test teardown.
ProviderContainer createAuthTestContainer({
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
