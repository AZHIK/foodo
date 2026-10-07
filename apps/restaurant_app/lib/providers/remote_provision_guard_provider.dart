/// Executes the remote-deprovision policy on every offline→online transition.
///
/// Flow: device locked to `(businessId, storeId)` in `DeviceConfig` goes
/// online → [checkRemoteProvision] asks the online database whether that
/// business/store still exists → on a deprovision signal this logs out and
/// wipes/unprovisions locally, then raises [deprovisionAlertProvider] so the
/// UI can explain why the user was signed out.
///
/// Policy (chosen by the business owner):
/// - Business gone remotely (deleted, or this user revoked → 403) ⇒ full
///   logout + [LocalProfileRepository.wipeAllLocalData] (all 20 tables) +
///   tokens cleared. The device returns to a factory-fresh state.
/// - Locked store gone but business alive ⇒ logout + tokens cleared +
///   [LocalProfileRepository.clearDeviceProvisioning] only (caches kept), so
///   the next login re-provisions the device to a surviving store.
///
/// Safety rules:
/// - Indeterminate (offline, 5xx, 401) NEVER wipes — only an authoritative
///   online 403/404 does.
/// - Reentrancy-guarded (`_inFlight`): overlapping online events and sync
///   triggers share one check.
/// - Runs BEFORE any outbox sync (see `syncTriggerProvider`): orphaned rows
///   for a deleted business/store must never be pushed. [runGuardCheck]
///   returns true when the caller may proceed to sync, false when a
///   deprovision was handled and sync must be skipped.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/identity_service_api.dart';
import '../auth/remote_provision_guard.dart';
import '../auth/token_storage.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';
import 'database_providers.dart';
import 'permissions_provider.dart';
import 'session_provider.dart';

/// Raised when a deprovision is executed, so the app can show a "signed out
/// because …" dialog. Consumed once (the dialog clears it on dismiss), same
/// pattern as `sessionExpiredAlertProvider`.
enum DeprovisionEvent {
  /// Online business deleted/revoked → logout + full local wipe.
  businessDeleted,

  /// Locked store deleted/revoked → logout + device unprovisioned.
  storeDeleted,
}

final deprovisionAlertProvider =
    StateProvider<DeprovisionEvent?>((ref) => null);

/// Runs one guard check against the current device lock.
///
/// Rule: the locked business id must exist in the online database — yes →
/// proceed (true), no → logout + wipe everything local and start afresh
/// (false). Works signed-out too (the public probe needs no session); only
/// the store-detail stage needs a token.
///
/// Never throws — all failures map to "proceed" (indeterminate).
///
/// Concurrent callers (cold-start check, connectivity transition,
/// late-token listener, pre-sync gate) share one in-flight check instead
/// of firing the same backend reads 2-3x at once.
Future<bool> runGuardCheck(Ref ref) {
  final flight = _sharedGuardFlight;
  if (flight != null) return flight;
  final future = _runGuardCheckInner(ref);
  _sharedGuardFlight = future;
  return future.whenComplete(() {
    if (identical(_sharedGuardFlight, future)) _sharedGuardFlight = null;
  });
}

Future<bool> _runGuardCheckInner(Ref ref) async {
  final repo = ref.read(localProfileRepositoryProvider);
  final device = await repo.currentDevice().catchError((_) => null);
  if (device == null) {
    debugPrint('[provision-guard] skip: device unprovisioned');
    return true; // Unprovisioned device: nothing to check.
  }

  final businessId = (device.businessId as String?) ?? '';
  final storeId = device.businessLocationId as String?;
  if (businessId.isEmpty) {
    debugPrint('[provision-guard] skip: empty business lock');
    return true;
  }

  // Prefer the live in-memory token, fall back to secure storage: on a cold
  // start this check routinely runs BEFORE AuthNotifier's async session
  // restore. Null is fine — the public business probe needs no session.
  var token = ref.read(authProvider).accessToken;
  token ??= await TokenStorage().getTokenSet().then(
        (s) => s?.accessToken,
        onError: (_) => null,
      );

  final api = IdentityServiceApi(dio: ref.read(identityServiceDioProvider));
  debugPrint(
    '[provision-guard] checking business=$businessId store=$storeId',
  );
  final result = await checkRemoteProvision(
    api: api,
    businessId: businessId,
    storeId: storeId,
    bearerToken: token,
  );
  debugPrint(
    '[provision-guard] result=${result.status}'
    '${result.reason == null ? '' : ' reason=${result.reason}'}',
  );

  if (!result.isDeprovisioned) return true;

  if (result.status == RemoteProvisionStatus.businessGone) {
    await _executeBusinessWipe(ref);
    ref.read(deprovisionAlertProvider.notifier).state =
        DeprovisionEvent.businessDeleted;
  } else {
    await _executeStoreUnprovision(ref);
    ref.read(deprovisionAlertProvider.notifier).state =
        DeprovisionEvent.storeDeleted;
  }
  return false;
}

/// Business gone: revoke online session (best-effort), clear tokens, wipe all
/// 20 local tables, drop both online + offline sessions.
Future<void> _executeBusinessWipe(Ref ref) async {
  try {
    await ref.read(authProvider.notifier).logout();
  } catch (_) {
    // Best-effort revocation — local wipe below still runs.
  }
  try {
    await TokenStorage().clearAllTokens();
  } catch (_) {}
  try {
    await ref.read(localProfileRepositoryProvider).wipeAllLocalData();
  } catch (_) {}
  try {
    ref.read(sessionProvider.notifier).signOut();
  } catch (_) {}
}

/// Store gone: same logout, but only the `DeviceConfig` lock is cleared —
/// profiles/caches stay so the next login re-provisions to a surviving store.
Future<void> _executeStoreUnprovision(Ref ref) async {
  try {
    await ref.read(authProvider.notifier).logout();
  } catch (_) {}
  try {
    await TokenStorage().clearTokenSet();
  } catch (_) {}
  try {
    await ref.read(localProfileRepositoryProvider).clearDeviceProvisioning();
  } catch (_) {}
  try {
    ref.read(sessionProvider.notifier).signOut();
  } catch (_) {}
}

/// Process-wide in-flight guard check shared by all trigger sites.
Future<bool>? _sharedGuardFlight;

/// Arms the offline→online → guard-check trigger. Watch once from the app
/// shell (alongside `syncTriggerProvider`); never read the value.
///
///
/// Fires on three occasions, because any single one can be the only signal:
/// - cold start already online (`isOnlineFutureProvider` resolves true —
///   the connectivity stream only emits *changes*, so a device that boots
///   online would otherwise never check);
/// - any offline→online transition;
/// - a fresh access token arriving late (cold start restores the in-memory
///   token asynchronously *after* the cold-start check; without this the
///   first check runs token-less and nothing retries it).
final remoteProvisionGuardProvider = Provider<void>((ref) {
  Future<void>? inFlight;

  Future<void> guardedCheck() {
    if (inFlight != null) return inFlight!;
    inFlight = runGuardCheck(ref).whenComplete(() => inFlight = null);
    return inFlight!;
  }

  var wasOnline = false;

  // Cold start: if already online with a device lock, check immediately.
  // (Token-storage fallback inside runGuardCheck covers the window before
  // AuthNotifier restores the in-memory token; the token listener below
  // covers the case even that is too early.)
  ref.read(isOnlineFutureProvider.future).then((online) {
    if (online) {
      wasOnline = true;
      unawaited(guardedCheck());
    }
  }).catchError((_) => null);

  ref.listen(isOnlineProvider, (previous, next) {
    next.whenData((isOnline) {
      if (!wasOnline && isOnline) {
        unawaited(guardedCheck());
      }
      wasOnline = isOnline;
    });
  });

  // A token arriving or changing (session restore, PIN-unlock refresh, OTP
  // login, context switch) re-arms the guard. Fires on ANY change to a
  // non-null token — the login flow moves null → unscoped (skipped: no
  // business context yet, see above) → scoped (verified for real).
  ref.listen(
    authProvider.select((a) => a.accessToken),
    (previous, next) {
      if (next != null && previous != next) {
        unawaited(guardedCheck());
      }
    },
  );

  // Rebuild (re-arm) when the locked business changes; the value itself
  // isn't used here (`runGuardCheck` re-reads live).
  ref.watch(currentBusinessIdProvider);
});
