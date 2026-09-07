/// Permission gating derived from the current session's real JWT — not a
/// separate client-side permission model that could drift from what the
/// backend actually enforces.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/jwt_decoder.dart';
import '../models/user_permissions.dart';
import 'auth_provider.dart';
import 'database_providers.dart';
import 'permissions_cache_tick_provider.dart';

/// The decoded claims of the current session's access token, or null when
/// signed out. This is the single source for "what business am I scoped to"
/// and "what can I do" — both come from the same token the backend itself
/// reads, so gating here can never invent a permission the backend doesn't
/// also recognize.
///
/// Note: `TokenRefreshInterceptor`'s silent 401-refresh updates
/// `TokenStorage` directly but not this in-memory `AuthContext` — so this
/// can go briefly stale relative to disk after a silent refresh mid-session.
/// Acceptable for gating (defense-in-depth only; the backend re-checks
/// every request against the fresh token regardless), not acceptable if
/// this value were ever the only check performed.
final currentClaimsProvider = Provider<JwtClaims?>((ref) {
  final token = ref.watch(authProvider.select((s) => s.accessToken));
  if (token == null) return null;
  try {
    return decodeAccessToken(token);
  } catch (_) {
    return null;
  }
});

/// This device's locked business, read from local `DeviceConfig` — the
/// offline-safe fallback for [currentBusinessIdProvider] when there's no
/// live token yet (the moment right after PIN unlock, before the online
/// refresh completes) or the device is offline. A device is locked to
/// exactly one business, so this is stable across sessions.
final _deviceBusinessIdProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(localProfileRepositoryProvider);
  final device = await repo.currentDevice();
  return device?.businessId as String?;
});

/// The business the current session is scoped to: the live token when one
/// is available, otherwise the device's locked business from local storage
/// — so callers that only need to know *which* business to read cached
/// data for (roles, permissions, staff) aren't blocked on a fresh token.
final currentBusinessIdProvider = Provider<String?>((ref) {
  final live = ref.watch(currentClaimsProvider)?.activeBusinessId;
  if (live != null) return live;
  return ref.watch(_deviceBusinessIdProvider).valueOrNull;
});

/// Effective permission codes for UI gating: always the local
/// `CachedPermissions` cache (via [currentUserPermissionsProvider]), never
/// the live token directly — so buttons/nav items read from the same
/// stable source whether online, offline, or mid-refresh right after PIN
/// unlock. Never used to authorize an actual backend request — the
/// backend re-checks every real request against the token itself, which is
/// kept current independently of this (see `AuthNotifier._refreshAndPersist`
/// / `_syncPermissionsCache`, which writes to this same cache).
final effectivePermissionsProvider = Provider<Set<String>>((ref) {
  final result = ref.watch(currentUserPermissionsProvider).valueOrNull;
  return result?.permissionsOrEmpty ?? const {};
});

/// Whether the current session carries [permissionCode] (or `*`), reading
/// from [effectivePermissionsProvider] (the local cache). This gates what
/// the UI shows, not what the backend allows — the backend independently
/// re-derives the real answer from the bearer token on every request.
///
/// Use `AppPermissions.*` constants (lib/models/permission.dart) as the
/// code — those ids are the real backend `PermissionCode` values, not a
/// separate catalogue.
final hasPermissionProvider = Provider.family<bool, String>((ref, permissionCode) {
  final permissions = ref.watch(effectivePermissionsProvider);
  return permissions.contains('*') || permissions.contains(permissionCode);
});

/// Maximum age of cached permissions before they are considered stale.
/// When permissions are older than this, they are marked stale but still
/// returned (some data is better than none for offline read-only operations).
const Duration _permissionsCacheTtl = Duration(hours: 24);

/// Current user's permissions, always read from the local `CachedPermissions`
/// table — never the live token directly, so the UI has exactly one source
/// of truth regardless of connectivity or refresh timing. The live token
/// (via [currentClaimsProvider]) is what actually authorizes backend
/// requests; this is a separate, deliberately stable read path for display.
///
/// Watches [currentClaimsProvider] and [permissionsCacheTickProvider]
/// purely as rebuild triggers, never as data sources. The claims watch
/// covers most refreshes (a new token usually means a cache write already
/// happened alongside it); the tick covers the case a claims change alone
/// would miss — e.g. `AuthNotifier.setPin` writing an invited staff
/// member's first cache entry, with no token change of its own to piggy-
/// back on. Every write site bumps the tick (see `syncPermissionsCache`
/// and `AuthNotifier._cachePermissions`) precisely so this doesn't need to
/// guess which trigger applies.
///
/// Returns the three-state result distinguishing:
/// - Known(permissions, isStale=false): cache is within the freshness TTL
/// - Known(permissions, isStale=true): cache exists but has gone stale
/// - Unknown(): no cache entry — never populated, or for a different user
final currentUserPermissionsProvider = FutureProvider<UserPermissionsResult>(
  (ref) async {
    ref.watch(currentClaimsProvider);
    ref.watch(permissionsCacheTickProvider);

    final userId = ref.watch(authProvider.select((a) => a.userId));
    if (userId == null) {
      return UserPermissionsResult.unknown();
    }

    final repo = ref.watch(localProfileRepositoryProvider);
    final cached = await repo.getPermissions(userId);

    if (cached == null) {
      return UserPermissionsResult.unknown();
    }

    // Parse permission codes from JSON.
    final permCodes = <String>{};
    try {
      final decoded = jsonDecode(cached.permissionCodes) as List<dynamic>;
      permCodes.addAll(decoded.cast<String>());
    } catch (_) {
      // If JSON decode fails, treat as unknown.
      return UserPermissionsResult.unknown();
    }

    // Check staleness against the configured TTL.
    final age = DateTime.now().difference(cached.cachedAt);
    final isStale = age > _permissionsCacheTtl;

    return UserPermissionsResult.known(
      permissions: permCodes,
      isStale: isStale,
    );
  },
);
