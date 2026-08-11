import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/tables/local_user_profiles.dart';

/// Persistence for device-local staff profiles.
///
/// All methods read and write the Drift [LocalUserProfiles] table, so
/// lockout state (attempt count, `pin_locked_until`) survives app
/// restarts — it is never held in memory only.
abstract class LocalProfileRepository {
  Future<List<LocalUserProfile>> listProfiles();
  Future<LocalUserProfile?> profileById(String userId);
  Future<LocalUserProfile> activeProfile();

  Future<void> upsertProfile({
    required String userId,
    required String phone,
    required String displayName,
    required String pinHash,
    String? activeBusinessId,
  });

  /// Marks [userId] as the currently active profile and deactivates all
  /// others.
  Future<void> activate(String userId);

  /// Deactivates the active profile, ending the current shift.
  Future<void> endShift();

  Future<void> removeProfile(String userId);

  Future<void> incrementPinAttempts(String userId, int count);
  Future<void> lockProfile(String userId, {required DateTime lockedUntil});
  Future<void> resetPinAttempts(String userId);
  Future<void> clearLockout(String userId);

  // ── Device config ────────────────────────────────────────────────
  /// Returns the current device config (single-row table).
  Future<DeviceConfig?> getDeviceConfig();

  /// Sets the device lock to the given business.
  Future<void> setDeviceLock({required String businessId, required String businessName});

  /// Clears the device lock (when the last profile is removed).
  Future<void> clearDeviceLock();
}

class DriftLocalProfileRepository implements LocalProfileRepository {
  DriftLocalProfileRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<LocalUserProfile>> listProfiles() async {
    final query = _db.select(_db.localUserProfiles)
      ..orderBy([(t) => OrderingTerm.desc(t.lastLoginAt)]);
    return query.get();
  }

  @override
  Future<LocalUserProfile?> profileById(String userId) async {
    final query = _db.select(_db.localUserProfiles)
      ..where((t) => t.userId.equals(userId));
    return query.getSingleOrNull();
  }

  @override
  Future<LocalUserProfile> activeProfile() async {
    final query = _db.select(_db.localUserProfiles)
      ..where((t) => t.isCurrentlyActive.equals(true));
    final profile = await query.getSingleOrNull();
    if (profile == null) {
      throw StateError('No active profile.');
    }
    return profile;
  }

  @override
  Future<void> upsertProfile({
    required String userId,
    required String phone,
    required String displayName,
    required String pinHash,
    String? activeBusinessId,
  }) async {
    await _db.transaction(() async {
      await _deactivateAll();
      await _db.into(_db.localUserProfiles).insertOnConflictUpdate(
            LocalUserProfilesCompanion(
              userId: Value(userId),
              phone: Value(phone),
              displayName: Value(displayName),
              pinHash: Value(pinHash),
              activeBusinessId: Value(activeBusinessId),
              lastLoginAt: Value(DateTime.now()),
              isCurrentlyActive: const Value(true),
            ),
          );
    });
  }

  @override
  Future<void> activate(String userId) async {
    await _db.transaction(() async {
      await _deactivateAll();
      await (_db.update(_db.localUserProfiles)
            ..where((t) => t.userId.equals(userId)))
          .write(
        LocalUserProfilesCompanion(
          isCurrentlyActive: const Value(true),
          lastLoginAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> endShift() async {
    await _deactivateAll();
  }

  @override
  Future<void> removeProfile(String userId) async {
    await (_db.delete(_db.localUserProfiles)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  @override
  Future<void> incrementPinAttempts(String userId, int count) async {
    await (_db.update(_db.localUserProfiles)
          ..where((t) => t.userId.equals(userId)))
        .write(LocalUserProfilesCompanion(pinAttemptCount: Value(count)));
  }

  @override
  Future<void> lockProfile(String userId,
      {required DateTime lockedUntil}) async {
    await (_db.update(_db.localUserProfiles)
          ..where((t) => t.userId.equals(userId)))
        .write(LocalUserProfilesCompanion(pinLockedUntil: Value(lockedUntil)));
  }

  @override
  Future<void> resetPinAttempts(String userId) async {
    await (_db.update(_db.localUserProfiles)
          ..where((t) => t.userId.equals(userId)))
        .write(
      const LocalUserProfilesCompanion(pinAttemptCount: Value(0)),
    );
  }

  @override
  Future<void> clearLockout(String userId) async {
    await (_db.update(_db.localUserProfiles)
          ..where((t) => t.userId.equals(userId)))
        .write(
      const LocalUserProfilesCompanion(
        pinAttemptCount: Value(0),
        pinLockedUntil: Value(null),
      ),
    );
  }

  // ── Device config ────────────────────────────────────────────────

  @override
  Future<DeviceConfig?> getDeviceConfig() async {
    final query = _db.select(_db.deviceConfigs);
    return query.getSingleOrNull();
  }

  @override
  Future<void> setDeviceLock({
    required String businessId,
    required String businessName,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.deviceConfigs).insertOnConflictUpdate(
      DeviceConfigsCompanion(
        id: const Value(1),
        lockedBusinessId: Value(businessId),
        lockedBusinessName: Value(businessName),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> clearDeviceLock() async {
    final now = DateTime.now();
    await _db.into(_db.deviceConfigs).insertOnConflictUpdate(
      DeviceConfigsCompanion(
        id: const Value(1),
        lockedBusinessId: const Value.absent(),
        lockedBusinessName: const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _deactivateAll() async {
    await (_db.update(_db.localUserProfiles)
          ..where((t) => t.isCurrentlyActive.equals(true)))
        .write(
      const LocalUserProfilesCompanion(isCurrentlyActive: Value(false)),
    );
  }
}

/// App-wide [LocalProfileRepository] backed by the Drift [AppDatabase].
final localProfileRepositoryProvider = Provider<LocalProfileRepository>((ref) {
  return DriftLocalProfileRepository(ref.watch(appDatabaseProvider));
});
