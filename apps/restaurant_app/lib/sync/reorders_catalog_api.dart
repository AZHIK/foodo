/// Pluggable interface for fetching reorders (restock purchase orders).
///
/// Mirrors `inventory_catalog_api.dart`'s shape — a pull-only read, no
/// outbox (see `suppliers_provider.dart`'s doc comment for why).
library;

import 'package:decimal/decimal.dart';

/// Data transfer object for a cached reorder.
class ReorderDto {
  final String id;
  final String businessId;
  final String storeId;
  final String itemId;
  final String supplierId;
  final Decimal quantity;
  final String unit;
  final Decimal unitCost;
  final String status;
  final String? notes;
  final DateTime orderedAt;
  final String? orderedBy;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final String? receivedBy;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final DateTime createdAt;

  ReorderDto({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.itemId,
    required this.supplierId,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.status,
    this.notes,
    required this.orderedAt,
    this.orderedBy,
    this.expectedAt,
    this.receivedAt,
    this.receivedBy,
    this.cancelledAt,
    this.cancelledBy,
    required this.createdAt,
  });
}

/// Pluggable API for fetching reorders.
abstract class ReordersCatalogApi {
  /// Fetches all reorders for a store.
  Future<List<ReorderDto>> fetchReorders({required String storeId});
}
