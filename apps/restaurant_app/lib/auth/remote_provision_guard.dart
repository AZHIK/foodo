/// Remote deprovision check: is the device's locked business still online?
///
/// The device is locked to one `(businessId, storeId)` pair (`DeviceConfig`)
/// and works offline-first against its local database. On every online
/// contact this answers one question: does the locked business id still
/// exist in the online database? Yes → proceed. No → logout + wipe everything
/// local and start afresh. See `remote_provision_guard_provider.dart` for
/// the execute side; this file is the pure check.
///
/// Two stages, deliberately split by what they need:
/// 1. PUBLIC business probe (`GET .../exists`, no session required): the
///    authoritative answer. 404 ⇒ business gone — even with no token, even
///    signed out. Anything else (offline, 5xx, malformed id) ⇒ indeterminate:
///    never wipe blind.
/// 2. SESSION store detail (only when a usable token exists): with the
///    business confirmed present, `business_store_staff` reads its own store
///    (`listStores` 403s them even when healthy) and `business_staff` lists
///    stores — a locked store that's absent ⇒ store gone (logout +
///    unprovision so the device can re-lock to a surviving store).
///
/// A token without a business context (fresh OTP login, pre-switch) skips
/// stage 2: both store probes would 403 on the missing context, which must
/// never read as "deleted". The post-switch scoped token re-triggers.
library;

import 'identity_service_api.dart';
import 'jwt_decoder.dart';

/// Outcome of one remote provision check.
enum RemoteProvisionStatus {
  /// Remote still has this business + store (or no device lock to check).
  ok,

  /// Backend unreachable, errored transiently, or no usable session for the
  /// store-detail stage. Keep working offline — never wipe on this.
  indeterminate,

  /// The locked business id is not on the server (public probe → 404), or
  /// the caller was revoked from it (store list → 403). Policy: full logout
  /// + local wipe, start afresh.
  businessGone,

  /// Business exists but the locked store is absent. Policy: logout +
  /// unprovision store so the device can re-lock to a surviving store.
  storeGone,
}

/// One check result with a human-readable reason for logs/dialogs.
class RemoteProvisionResult {
  final RemoteProvisionStatus status;
  final String? reason;

  const RemoteProvisionResult(this.status, [this.reason]);

  bool get isDeprovisioned =>
      status == RemoteProvisionStatus.businessGone ||
      status == RemoteProvisionStatus.storeGone;
}

/// Validates the device's locked `(businessId, storeId)` against the online
/// database. [bearerToken] may be null (signed out) — the public business
/// probe still runs; only the store-detail stage is skipped. Never throws —
/// transport errors map to `indeterminate`.
Future<RemoteProvisionResult> checkRemoteProvision({
  required IdentityServiceApi api,
  required String businessId,
  String? storeId,
  String? bearerToken,
}) async {
  // Stage 1 — public, session-free: does this business id exist online?
  try {
    await api.businessExists(businessId: businessId);
  } on AuthException catch (e) {
    if (e.statusCode == 404) {
      return RemoteProvisionResult(
        RemoteProvisionStatus.businessGone,
        'Business $businessId not found online (deleted).',
      );
    }
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Business probe indeterminate: ${e.message}',
    );
  } catch (e) {
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Business probe failed: $e',
    );
  }

  // Stage 2 — store detail needs a session.
  if (bearerToken == null || bearerToken.isEmpty) {
    return const RemoteProvisionResult(RemoteProvisionStatus.ok);
  }
  String userCategory = '';
  String? tokenBusinessId;
  try {
    final claims = decodeAccessToken(bearerToken);
    userCategory = claims.userCategory ?? '';
    tokenBusinessId = claims.activeBusinessId;
  } catch (_) {
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Undecodable token — not proof of deletion.',
    );
  }
  if (userCategory != 'business_store_staff' &&
      (tokenBusinessId == null || tokenBusinessId.isEmpty)) {
    return const RemoteProvisionResult(RemoteProvisionStatus.ok);
  }

  if (userCategory == 'business_store_staff') {
    return _checkSingleStore(
      api: api,
      businessId: businessId,
      storeId: storeId,
      bearerToken: bearerToken,
    );
  }
  return _checkStoreMembership(
    api: api,
    businessId: businessId,
    storeId: storeId,
    bearerToken: bearerToken,
  );
}

/// Store-staff probe (blocked from `listStores` even when healthy): a 200 on
/// the locked store proves presence; 404/403 means the lock is invalid.
Future<RemoteProvisionResult> _checkSingleStore({
  required IdentityServiceApi api,
  required String businessId,
  required String? storeId,
  required String bearerToken,
}) async {
  if (storeId == null || storeId.isEmpty) {
    return const RemoteProvisionResult(RemoteProvisionStatus.ok);
  }
  try {
    await api.getStore(
      businessId: businessId,
      storeId: storeId,
      bearerToken: bearerToken,
    );
    return const RemoteProvisionResult(RemoteProvisionStatus.ok);
  } on AuthException catch (e) {
    final s = e.statusCode;
    if (s == 404 || s == 403) {
      return RemoteProvisionResult(
        RemoteProvisionStatus.storeGone,
        'Assigned store invalid online ($s): ${e.message}',
      );
    }
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Store check indeterminate: ${e.message}',
    );
  } catch (e) {
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Store check failed: $e',
    );
  }
}

/// Business-staff probe: a 200 list settles store presence; 403 means the
/// caller's membership is gone (revoked) ⇒ business-gone.
Future<RemoteProvisionResult> _checkStoreMembership({
  required IdentityServiceApi api,
  required String businessId,
  required String? storeId,
  required String bearerToken,
}) async {
  try {
    final stores = await api.listStores(
      businessId: businessId,
      bearerToken: bearerToken,
    );
    if (storeId == null || storeId.isEmpty) {
      return const RemoteProvisionResult(RemoteProvisionStatus.ok);
    }
    final found = stores.any((s) => s.id == storeId);
    if (!found) {
      return RemoteProvisionResult(
        RemoteProvisionStatus.storeGone,
        'Store $storeId no longer exists in business $businessId.',
      );
    }
    return const RemoteProvisionResult(RemoteProvisionStatus.ok);
  } on AuthException catch (e) {
    final s = e.statusCode;
    if (s == 404 || s == 403) {
      return RemoteProvisionResult(
        RemoteProvisionStatus.businessGone,
        'Access to business $businessId lost ($s).',
      );
    }
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Store list indeterminate: ${e.message}',
    );
  } catch (e) {
    return RemoteProvisionResult(
      RemoteProvisionStatus.indeterminate,
      'Store list failed: $e',
    );
  }
}
