/// Pluggable interface for fetching the supplier directory.
///
/// Mirrors `inventory_catalog_api.dart`'s shape — a pull-only read, no
/// outbox (see `suppliers_provider.dart`'s doc comment for why).
library;

/// Data transfer object for a cached supplier.
class SupplierDto {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? addressLine1;
  final String? notes;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime createdAt;

  SupplierDto({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.addressLine1,
    this.notes,
    required this.updatedAt,
    required this.isDeleted,
    required this.createdAt,
  });
}

/// Pluggable API for fetching the supplier directory.
abstract class SuppliersCatalogApi {
  /// Fetches all suppliers for the business (including soft-deleted, so a
  /// delete made on one device propagates to every other device's cache).
  Future<List<SupplierDto>> fetchSuppliers();
}
