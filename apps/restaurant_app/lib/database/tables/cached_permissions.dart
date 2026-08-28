/// Local cache of a staff member's role and permissions for offline RBAC.
///
/// `CachedPermissions` is a pull-only cache from Identity Service: the
/// server is unconditionally authoritative, refreshed wholesale (full
/// REPLACE by `userId`) on login, business-context switch, and periodic
/// reconnect. There is no local write path — the app never mutates a
/// permission set, only re-fetches it.
///
/// Cascades on `userId` delete: when a profile is remotely revoked (see
/// `LocalUserProfiles`), its cached permissions are removed with it rather
/// than surviving as stale, unreachable rows.
library;

import 'package:drift/drift.dart';
import 'local_user_profiles.dart';

/// Local cache of a staff member's role and permissions for offline RBAC.
class CachedPermissions extends Table {
  /// Staff member's UUID; also the foreign key to `LocalUserProfiles.id`.
  TextColumn get userId => text().references(
        LocalUserProfiles,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Business this permission set applies to.
  TextColumn get businessId => text()();

  /// Cached business name for offline display.
  TextColumn get businessName => text()();

  /// Business location this permission set applies to.
  TextColumn get businessLocationId => text()();

  /// Cached display-only role name.
  TextColumn get roleName => text()();

  /// JSON-encoded list of permission codes granted to this role.
  TextColumn get permissionCodes => text()();

  /// When this permission set was last refreshed from the server.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
