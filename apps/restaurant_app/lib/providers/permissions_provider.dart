/// Permission gating derived from the current session's real JWT — not a
/// separate client-side permission model that could drift from what the
/// backend actually enforces.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/jwt_decoder.dart';
import 'auth_provider.dart';

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
