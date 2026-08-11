import 'dart:convert';

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
import 'package:foodlink_business/features/business/data/business_api.dart';
import 'package:foodlink_business/features/business/domain/business_create_request.dart';
import 'package:foodlink_business/features/business/domain/business_create_response.dart';

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

/// Builds a JWT-shaped access token whose payload carries the given claims.
///
/// `sub` is always required (the real client parses it from the token); for a
/// business-scoped token pass a non-null [activeBusinessId] plus
/// [roles]/[permissions]. Tests can decode it back with [decodeJwtPayload].
String buildScopedToken({
  required String userId,
  String? activeBusinessId,
  List<String> roles = const [],
  List<String> permissions = const [],
}) {
  String enc(Map<String, dynamic> map) =>
      base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');

  final header = enc({'alg': 'RS256', 'typ': 'JWT'});
  final payload = enc({
    'sub': userId,
    'active_business_id': activeBusinessId,
    'roles': roles,
    'permissions': permissions,
  });
  return '$header.$payload.signature';
}

/// Decodes the unverified payload of a JWT-shaped token (test helper only).
Map<String, dynamic> decodeJwtPayload(String token) {
  final segments = token.split('.');
  final payload =
      utf8.decode(base64Url.decode(base64Url.normalize(segments[1])));
  return jsonDecode(payload) as Map<String, dynamic>;
}

class FakeIdentityApi implements IdentityApi {
  FakeIdentityApi({
    required this.userId,
    required this.refreshToken,
    required this.validCode,
    this.needsOnboarding = false,
    this.businessId,
    this.businessName,
    this.needsOnboardingAfterBusinessCreation = false,
    this.businessIdAfterCreation,
    this.businessNameAfterCreation,
    this.switchBusinessContextFailure,
  });

  final String userId;
  final String refreshToken;
  final String validCode;

  /// Returned by [fetchOnboardingStatus] for the initial check.
  /// Defaults to `false` (invited staff) so existing tests that expect
  /// `setPin` → `SessionActive` continue to pass unchanged.
  final bool needsOnboarding;
  final String? businessId;
  final String? businessName;

  /// Optional: returned by [fetchOnboardingStatus] after business creation
  /// (i.e., on the second+ call). Useful for tests that simulate completing
  /// onboarding and then re-checking status.
  final bool needsOnboardingAfterBusinessCreation;
  final String? businessIdAfterCreation;
  final String? businessNameAfterCreation;

  /// When set, [switchBusinessContext] throws this [Failure] instead of
  /// returning a scoped token (used to exercise the retry paths).
  Failure? switchBusinessContextFailure;

  int requestOtpCalls = 0;
  int verifyOtpCalls = 0;
  int onboardingStatusCalls = 0;
  int refreshAccessTokenCalls = 0;
  int switchBusinessContextCalls = 0;

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
      // The OTP-issued token is unscoped (this is the bug we're fixing):
      // no active_business_id, no roles/permissions.
      accessToken: buildScopedToken(userId: userId),
      refreshToken: refreshToken,
    );
  }

  @override
  Future<OnboardingStatusResult> fetchOnboardingStatus() async {
    onboardingStatusCalls++;
    // After the first call, optionally return the "after business creation" values.
    if (onboardingStatusCalls > 1 &&
        needsOnboardingAfterBusinessCreation != needsOnboarding) {
      return OnboardingStatusResult(
        needsOnboarding: needsOnboardingAfterBusinessCreation,
        businessId: businessIdAfterCreation ?? businessId,
        businessName: businessNameAfterCreation ?? businessName,
      );
    }
    return OnboardingStatusResult(
      needsOnboarding: needsOnboarding,
      businessId: businessId,
      businessName: businessName,
    );
  }

  @override
  Future<OtpVerificationResult> refreshAccessToken(String refreshToken) async {
    refreshAccessTokenCalls++;
    return OtpVerificationResult(
      userId: userId,
      // Refresh also returns an unscoped token server-side.
      accessToken: buildScopedToken(userId: userId),
      // Refresh tokens rotate server-side; hand back a distinct token so
      // callers that persist the rotated value are visibly exercised.
      refreshToken: 'rt_rotated_$refreshToken',
    );
  }

  @override
  Future<OtpVerificationResult> switchBusinessContext(String businessId) async {
    switchBusinessContextCalls++;
    final toThrow = switchBusinessContextFailure;
    if (toThrow != null) throw toThrow;
    return OtpVerificationResult(
      userId: userId,
      // Business-scoped token: carries active_business_id, roles and
      // permissions, and rotates the refresh token.
      accessToken: buildScopedToken(
        userId: userId,
        activeBusinessId: businessId,
        roles: const ['owner'],
        permissions: const ['business.read', 'business.write'],
      ),
      refreshToken: 'rt_rotated_$refreshToken',
    );
  }
}

/// Records business-creation calls and lets a test inject a failure.
class FakeBusinessApi implements BusinessApi {
  final List<BusinessCreateRequest> createCalls = [];

  /// When set, [createBusiness] throws this [Failure] instead of recording.
  Failure? failure;

  @override
  Future<BusinessCreateResult> createBusiness(
    BusinessCreateRequest request,
  ) async {
    final toThrow = failure;
    if (toThrow != null) throw toThrow;
    createCalls.add(request);
    return BusinessCreateResult(
      id: 'biz_1',
      name: request.name,
      ownerRoleName: 'Owner',
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
  FakeLocalProfileRepository() {
    _deviceConfig = DeviceConfig(
      id: 1,
      lockedBusinessId: null,
      lockedBusinessName: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  final Map<String, LocalUserProfile> profiles = {};
  DeviceConfig? _deviceConfig;

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

  @override
  Future<DeviceConfig?> getDeviceConfig() async => _deviceConfig;

  @override
  Future<void> setDeviceLock({
    required String businessId,
    required String businessName,
  }) async {
    _deviceConfig = DeviceConfig(
      id: 1,
      lockedBusinessId: businessId,
      lockedBusinessName: businessName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> clearDeviceLock() async {
    _deviceConfig = DeviceConfig(
      id: 1,
      lockedBusinessId: null,
      lockedBusinessName: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
