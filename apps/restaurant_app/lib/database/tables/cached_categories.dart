/// Product categories cached from Inventory Service, for the item form's
/// category picker and the Groceries/Menu Items filter panels.
///
/// `CachedCategories` mirrors the backend's `CategoryRead` schema (from
/// `services/inventory-service/app/schemas/categories.py`) — a pull-only
/// read cache, global rather than business-scoped (unlike `CachedSuppliers`)
/// since categories are a single platform-wide taxonomy. No soft-delete
/// column either: the backend never lets a referenced category disappear
/// (`Item.category_id` is `ondelete=RESTRICT`), so `isActive=false` is the
/// only "retired" state that can ever occur.
library;

import 'package:drift/drift.dart';

/// Product categories cached from Inventory Service.
class CachedCategories extends Table {
  /// Category UUID (primary key), server-assigned.
  TextColumn get id => text()();

  /// Stable slug (e.g. `produce`) — not used by the UI directly, kept for
  /// debugging/traceability back to the seed migration.
  TextColumn get code => text()();

  TextColumn get name => text()();

  /// Display ordering for pickers/filters, ascending.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Local timestamp of the most recent pull that included this row.
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
