/// Keeps the local `CachedPermissions` table — the UI's one source for
/// permission gating (see `effectivePermissionsProvider`) — in step with
/// whatever a live access token actually grants, any time one is freshly
/// obtained: PIN unlock, cold-start refresh, or a background 401 refresh.
library;

import 'dart:convert';

import '../database/app_database.dart';
import '../database/local_profile_repository.dart';
import 'jwt_decoder.dart';

/// Best-effort: a brand-new invited staff member has no `LocalUserProfiles`
/// row yet at OTP/context-switch time (that's only created once they reach
/// Complete Profile / Set PIN) — silently skipping then just leaves that
/// first write to do the job, not a crash.
///
/// [onSynced], if given, runs only after a successful write — callers with
/// Riverpod `ref` access use it to bump `permissionsCacheTickProvider`, the
/// signal `currentUserPermissionsProvider` needs to notice the write (a
/// plain database write has no Riverpod dependency of its own).
Future<void> syncPermissionsCache({
  required LocalProfileRepository profileRepo,
  required String userId,
  required String accessToken,
  void Function()? onSynced,
}) async {
  try {
    final claims = decodeAccessToken(accessToken);
    final businessId = claims.activeBusinessId;
    if (businessId == null) return;

    final device = await profileRepo.currentDevice();
    await profileRepo.upsertPermissions(
      CachedPermissionsCompanion.insert(
        userId: userId,
        businessId: businessId,
        businessName: (device?.businessName as String?) ?? '',
        businessLocationId: (device?.businessLocationId as String?) ?? '',
        roleName: claims.roles.isNotEmpty ? claims.roles.join(', ') : 'Staff',
        permissionCodes: jsonEncode(claims.permissions),
        cachedAt: DateTime.now(),
      ),
    );
    onSynced?.call();
  } catch (_) {
    // No profile row yet, offline cache write failure, or a malformed
    // token — a stale cache just means stale display, not a broken
    // session.
  }
}
