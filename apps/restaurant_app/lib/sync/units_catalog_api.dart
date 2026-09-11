/// Pluggable interface for fetching the unit-of-measure taxonomy.
///
/// Mirrors `categories_catalog_api.dart`'s shape — a pull-only read, no
/// outbox (units are read-only from the app's perspective; see
/// `services/inventory-service/app/api/v1/endpoints/units.py`).
library;

/// Data transfer object for a cached unit.
class UnitDto {
  final String id;
  final String code;
  final String name;
  final String abbreviation;
  final int sortOrder;
  final bool isActive;

  UnitDto({
    required this.id,
    required this.code,
    required this.name,
    required this.abbreviation,
    required this.sortOrder,
    required this.isActive,
  });
}

/// Pluggable API for fetching the unit-of-measure taxonomy.
abstract class UnitsCatalogApi {
  /// Fetches every active unit. Unlike suppliers, there is no
  /// `includeInactive` pull here — the app never needs to show a retired
  /// unit to a user picking one for an item.
  Future<List<UnitDto>> fetchUnits();
}
