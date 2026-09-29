/// Bridges the backend-shaped supplier cache (`CachedSuppliers`) onto the
/// UI's `Supplier` model. Mirrors `inventory_item_mapper.dart`'s shape.
library;

import '../database/app_database.dart';
import '../models/supplier.dart';

Supplier supplierFromCachedRow(CachedSupplier row) => Supplier(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      addressLine1: row.addressLine1,
      notes: row.notes,
      createdAt: row.createdAt,
    );
