/// Pluggable interface for fetching the product-category taxonomy.
///
/// Mirrors `suppliers_catalog_api.dart`'s shape — a pull-only read, no
/// outbox (categories are read-only from the app's perspective; see
/// `services/inventory-service/app/api/v1/endpoints/categories.py`).
library;

/// Data transfer object for a cached category.
class CategoryDto {
  final String id;
  final String code;
  final String name;
  final int sortOrder;
  final bool isActive;

  CategoryDto({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });
}

/// Pluggable API for fetching the product-category taxonomy.
abstract class CategoriesCatalogApi {
  /// Fetches every active category. Unlike suppliers, there is no
  /// `includeInactive` pull here — the app never needs to show a retired
  /// category to a user picking one for an item.
  Future<List<CategoryDto>> fetchCategories();
}
