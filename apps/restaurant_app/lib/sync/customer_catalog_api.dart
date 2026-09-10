/// Pluggable interface for fetching the customer ledger from POS Service.
///
/// The read-side counterpart to `customer_sync_api.dart`, mirroring how
/// `finance_catalog_api.dart` pairs with `finance_sync_api.dart`.
/// Business-scoped — no `storeId` parameter, unlike the finance/sales
/// catalog APIs.
library;

import 'package:decimal/decimal.dart';

/// Mirrors the backend's `CustomerRead`/`CustomerListItem`.
class CustomerServerDto {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String? email;
  final String? addressLine1;
  final String? actorId;
  final DateTime joinedAt;
  final DateTime syncedAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime createdAt;
  final int totalOrders;
  final Decimal totalSpent;
  final DateTime? lastOrderAt;

  CustomerServerDto({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    this.email,
    this.addressLine1,
    this.actorId,
    required this.joinedAt,
    required this.syncedAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.createdAt,
    required this.totalOrders,
    required this.totalSpent,
    this.lastOrderAt,
  });
}

/// Pluggable API for fetching the customer ledger.
abstract class CustomerCatalogApi {
  /// Fetches all customers for the business, including soft-deleted rows
  /// (so a delete made on another device propagates into this device's
  /// cache — see `customer_ledger_sync_service.dart`).
  Future<List<CustomerServerDto>> fetchCustomers();
}
