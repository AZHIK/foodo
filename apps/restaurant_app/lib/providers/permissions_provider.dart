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

/// The business the current session is scoped to, straight from the token
/// the backend itself authorizes requests against.
final currentBusinessIdProvider = Provider<String?>(
  (ref) => ref.watch(currentClaimsProvider)?.activeBusinessId,
);

/// Whether the current session's token carries [permissionCode] (or `*`).
///
/// Use `AppPermissions.*` constants (lib/models/permission.dart) as the
/// code — those ids are the real backend `PermissionCode` values, not a
/// separate catalogue.
final hasPermissionProvider = Provider.family<bool, String>(
  (ref, permissionCode) =>
      ref.watch(currentClaimsProvider)?.can(permissionCode) ?? false,
);

/// Maximum age of cached permissions before they are considered stale.
/// When permissions are older than this, they are marked stale but still
/// returned (some data is better than none for offline read-only operations).
const Duration _permissionsCacheTtl = Duration(hours: 24);

/// Current user's permissions: online (fresh token claims) or offline
/// (cached), with explicit staleness and missing-cache signals.
///
/// This is a READ-ONLY knowledge layer — it answers "what do we know about
/// the current user's permissions?" without gating anything. Gating comes
/// later (enforcement phase). For now, this is infrastructure for tests and
/// future enforcement to depend on.
///
/// Logic:
/// 1. Online with in-memory token claims → use those (freshest)
/// 2. Offline or no token → read CachedPermissions, check staleness
/// 3. No cache entry → return Unknown()
///
/// Returns the three-state result distinguishing:
/// - Known(permissions, isStale=false): Fresh data, live or recently cached
/// - Known(permissions, isStale=true): Stale cache, device offline since
/// - Unknown(): No cache, never populated or deleted
final currentUserPermissionsProvider = FutureProvider<UserPermissionsResult>(
  (ref) async {
    final claims = ref.watch(currentClaimsProvider);

    // Online: use in-memory token claims (always fresh).
    if (claims != null) {
      return UserPermissionsResult.known(
        permissions: Set.from(claims.permissions),
        isStale: false,
      );
    }

    // Offline or no token: try to read cached permissions.
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
