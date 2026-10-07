/// Tests for the remote-deprovision guard.
///
/// Covers `checkRemoteProvision` (online business/store existence check) and
/// the local wipe/unprovision helpers: business-gone ⇒ full wipe, store-gone
/// ⇒ DeviceConfig cleared, offline/5xx ⇒ indeterminate (never wipe).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/auth/identity_service_api.dart';
import 'package:restaurant_pos/auth/remote_provision_guard.dart';
import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/database/local_profile_repository.dart';
import 'package:restaurant_pos/providers/auth_provider.dart';
import 'package:restaurant_pos/providers/database_providers.dart';
import 'package:restaurant_pos/providers/remote_provision_guard_provider.dart';

import '../test_helpers/test_container.dart';

/// Minimal canned backend: maps "METHOD path" → (status, json body).
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.routes);
  final Map<String, (int, Object?)> routes;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.uri.path}';
    final hit = routes[key];
    if (hit == null) {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'Not found (test): $key'}),
        404,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
    return ResponseBody.fromString(
      hit.$2 == null ? '' : jsonEncode(hit.$2),
      hit.$1,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }
}

IdentityServiceApi _apiWith(Map<String, (int, Object?)> routes) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'));
  dio.httpClientAdapter = _CannedAdapter(routes);
  return IdentityServiceApi(dio: dio);
}

Map<String, dynamic> _storeJson(String businessId, String storeId) {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'id': storeId,
    'business_id': businessId,
    'name': 'Main',
    'token': 'tok-$storeId',
    'location_type': 'restaurant_branch',
    'status': 'active',
    'country_code': 'TZ',
    'city': null,
    'address': null,
    'timezone': 'Africa/Dar_es_Salaam',
    'is_primary': true,
    'created_at': now,
    'updated_at': now,
  };
}

/// Unsigned test JWT (the app never verifies signatures client-side).
String _unsignedJwt(Map<String, dynamic> claims) {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${segment({'alg': 'none'})}.${segment(claims)}.sig';
}

/// Scoped business_staff token for [businessId].
String _staffToken([String businessId = 'biz-1']) => _unsignedJwt({
      'sub': 'user-1',
      'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 900,
      'user_category': 'business_staff',
      'active_business_id': businessId,
    });

/// Scoped store-staff token for [businessId]/[storeId].
String _storeStaffToken([
  String businessId = 'biz-1',
  String storeId = 'store-1',
]) =>
    _unsignedJwt({
      'sub': 'user-2',
      'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 900,
      'user_category': 'business_store_staff',
      'active_business_id': businessId,
      'active_store_id': storeId,
    });

/// Business probe hit: 200 with the probe body.
(int, Object?) _existsOk() =>
    (200, {'business_id': 'biz-1', 'exists': true});

void main() {
  group('checkRemoteProvision — public business probe (no session needed)', () {
    test('businessGone on probe 404, even signed out', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-9/exists': (
          404,
          {'detail': 'Business not found'}
        ),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-9',
        storeId: 'store-1',
      );
      expect(r.status, RemoteProvisionStatus.businessGone);
    });

    test('indeterminate on probe 500 (never wipe)', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': (500, {'detail': 'boom'}),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _staffToken(),
      );
      expect(r.status, RemoteProvisionStatus.indeterminate);
      expect(r.isDeprovisioned, isFalse);
    });

    test('ok when business exists and no session (store stage skipped)',
        () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
      );
      expect(r.status, RemoteProvisionStatus.ok);
    });
  });

  group('checkRemoteProvision (business_staff store stage)', () {
    test('ok when business + store both exist', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
        'GET /api/v1/businesses/biz-1/stores': (
          200,
          [
            {'id': 'store-1', 'is_primary': true, 'name': 'Main'},
          ]
        ),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _staffToken(),
      );
      expect(r.status, RemoteProvisionStatus.ok);
    });

    test('storeGone when store missing from list', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
        'GET /api/v1/businesses/biz-1/stores': (
          200,
          [
            {'id': 'store-other', 'is_primary': true, 'name': 'Other'},
          ]
        ),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _staffToken(),
      );
      expect(r.status, RemoteProvisionStatus.storeGone);
    });

    test('businessGone when membership revoked (list 403)', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
        'GET /api/v1/businesses/biz-1/stores': (403, {'detail': 'Forbidden'}),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _staffToken(),
      );
      expect(r.status, RemoteProvisionStatus.businessGone);
    });
  });

  group('checkRemoteProvision (business_store_staff)', () {
    test('ok when own store reads 200', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
        'GET /api/v1/businesses/biz-1/stores/store-1': (
          200,
          _storeJson('biz-1', 'store-1')
        ),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _storeStaffToken(),
      );
      expect(r.status, RemoteProvisionStatus.ok);
    });

    test('storeGone when own store is 404 (deleted)', () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
        'GET /api/v1/businesses/biz-1/stores/store-1': (
          404,
          {'detail': 'Store not found'}
        ),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _storeStaffToken(),
      );
      expect(r.status, RemoteProvisionStatus.storeGone);
    });

    test('business probe wins: store 200 but business 404 ⇒ businessGone',
        () async {
      final api = _apiWith({
        'GET /api/v1/businesses/biz-1/exists': (
          404,
          {'detail': 'Business not found'}
        ),
      });
      final r = await checkRemoteProvision(
        api: api,
        businessId: 'biz-1',
        storeId: 'store-1',
        bearerToken: _storeStaffToken(),
      );
      expect(r.status, RemoteProvisionStatus.businessGone);
    });
  });

  group('local wipe / unprovision', () {
    late AppDatabase db;
    late LocalProfileRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = LocalProfileRepository(db);
    });

    tearDown(() async => db.close());

    Future<void> seed() async {
      final now = DateTime.now();
      await repo.provisionDevice(
        businessId: 'biz-1',
        businessLocationId: 'store-1',
        businessName: 'Test Biz',
      );
      await repo.upsertProfile(
        LocalUserProfilesCompanion.insert(
          id: 'user-1',
          displayName: 'Owner',
          pinHash: 'h',
          pinSalt: 's',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('clearDeviceProvisioning keeps profiles, drops lock', () async {
      await seed();
      await repo.clearDeviceProvisioning();
      expect(await repo.currentDevice(), isNull);
      expect(await repo.getProfile('user-1'), isNotNull);
    });

    test('wipeAllLocalData clears everything', () async {
      await seed();
      await repo.wipeAllLocalData();
      expect(await repo.currentDevice(), isNull);
      expect(await repo.getProfile('user-1'), isNull);
      expect(await repo.activeProfiles(), isEmpty);
    });

    test('reprovisionDevice to another business wipes first (fresh start)',
        () async {
      await seed(); // locked to biz-1 with a profile
      await repo.reprovisionDevice(
        businessId: 'biz-2',
        businessLocationId: 'store-9',
        businessName: 'New Biz',
      );
      final device = await repo.currentDevice();
      expect(device?.businessId as String?, 'biz-2');
      expect(await repo.getProfile('user-1'), isNull);
      expect(await repo.activeProfiles(), isEmpty);
    });

    test('reprovisionDevice to the same business keeps data', () async {
      await seed(); // locked to biz-1 with a profile
      await repo.reprovisionDevice(
        businessId: 'biz-1',
        businessLocationId: 'store-2',
        businessName: 'Test Biz',
      );
      final device = await repo.currentDevice();
      expect(device?.businessLocationId as String?, 'store-2');
      expect(await repo.getProfile('user-1'), isNotNull);
    });
  });

  group('runGuardCheck orchestration', () {
    /// Dio that explodes if any HTTP is attempted — the skip paths must
    /// return before touching the network.
    Dio explodingDio() {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'));
      dio.httpClientAdapter = _ExplodingAdapter();
      return dio;
    }

    test('unscoped business_staff token skips store stage (mid-login)',
        () async {
      final unscoped = _unsignedJwt({
        'sub': 'user-1',
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 900,
        'user_category': 'business_staff',
      });
      // Probe says the business exists; the store list answers 404 — if the
      // guard wrongly ran the store stage with the context-less token it
      // would report businessGone and wipe. It must not.
      final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'));
      dio.httpClientAdapter = _CannedAdapter({
        'GET /api/v1/businesses/biz-1/exists': _existsOk(),
      });
      final container = newTestContainer(extraOverrides: [
        authProvider.overrideWith(
          () => _FixedAuth(AuthContext(
            state: AuthState.complete,
            accessToken: unscoped,
            userId: 'user-1',
          )),
        ),
        identityServiceDioProvider.overrideWithValue(dio),
      ]);
      final repo = container.read(localProfileRepositoryProvider);
      await repo.provisionDevice(
        businessId: 'biz-1',
        businessLocationId: 'store-1',
        businessName: 'Test Biz',
      );

      expect(await container.read(_probe.future), isTrue);
      expect(await repo.currentDevice(), isNotNull);
    });

    test('probe 404 wipes even signed out (no session needed)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'));
      dio.httpClientAdapter = _CannedAdapter({
        'GET /api/v1/businesses/biz-1/exists': (
          404,
          {'detail': 'Business not found'}
        ),
      });
      final container = newTestContainer(extraOverrides: [
        identityServiceDioProvider.overrideWithValue(dio),
      ]);
      final repo = container.read(localProfileRepositoryProvider);
      await repo.provisionDevice(
        businessId: 'biz-1',
        businessLocationId: 'store-1',
        businessName: 'Test Biz',
      );

      expect(await container.read(_probe.future), isFalse);
      expect(await repo.currentDevice(), isNull);
      expect(
        container.read(deprovisionAlertProvider),
        DeprovisionEvent.businessDeleted,
      );
    });

    test('unprovisioned device never touches HTTP', () async {
      final container = newTestContainer(extraOverrides: [
        identityServiceDioProvider.overrideWithValue(explodingDio()),
      ]);
      expect(await container.read(_probe.future), isTrue);
    });
  });
}

/// AuthNotifier stub returning a fixed context without touching storage.
class _FixedAuth extends AuthNotifier {
  _FixedAuth(this._ctx);

  final AuthContext _ctx;

  @override
  AuthContext build() => _ctx;
}

/// Runs the guard inside a container (ProviderContainer is not a Ref).
final _probe = FutureProvider<bool>(runGuardCheck);

/// HttpClientAdapter that fails any request — skip paths must not call it.
class _ExplodingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw StateError(
      'HTTP must not be called (got ${options.method} ${options.uri})',
    );
  }
}
