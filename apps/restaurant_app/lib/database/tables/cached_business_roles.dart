/// Local cache of all business roles for a business.
///
/// Populated when rolesProvider loads from the API, so roles are available
/// offline and the app doesn't get stuck loading if the API is unavailable.
/// Cache is refreshed on each roles load/refresh.
library;

import 'package:drift/drift.dart';

class CachedBusinessRoles extends Table {
  /// The business these roles belong to.
  TextColumn get businessId => text()();

  /// Role UUID from the backend.
  TextColumn get roleId => text()();

  /// Role display name (e.g., "Manager", "Cashier").
  TextColumn get name => text()();

  /// Role description.
  TextColumn get description => text()();

  /// Whether this role is protected (system-defined).
  BoolColumn get isProtected => boolean()();

  /// JSON-encoded list of permission codes for this role.
  TextColumn get permissionCodes => text()();

  /// When this role cache was last refreshed from the server.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {businessId, roleId};
}
