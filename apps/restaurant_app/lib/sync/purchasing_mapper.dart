/// Bridges the backend-shaped cache (`CachedSuppliers`/`CachedReorders`)
/// onto the UI's `Supplier`/`Reorder` models. Mirrors
/// `inventory_item_mapper.dart`'s shape.
library;

import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../models/reorder.dart';
import '../models/supplier.dart';

double _toDouble(Decimal value) => double.parse(value.toString());

Supplier supplierFromCachedRow(CachedSupplier row) => Supplier(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      addressLine1: row.addressLine1,
      notes: row.notes,
      createdAt: row.createdAt,
    );

Reorder reorderFromCachedRow(CachedReorder row) => Reorder(
      id: row.id,
      storeId: row.storeId,
      inventoryItemId: row.itemId,
      quantity: _toDouble(row.quantity),
      unit: row.unit,
      unitCost: _toDouble(row.unitCost),
      supplierId: row.supplierId,
      orderedAt: row.orderedAt,
      expectedAt: row.expectedAt,
      receivedAt: row.receivedAt,
      cancelledAt: row.cancelledAt,
      status: switch (row.status) {
        'received' => ReorderStatus.received,
        'cancelled' => ReorderStatus.cancelled,
        _ => ReorderStatus.pending,
      },
      notes: row.notes,
    );
