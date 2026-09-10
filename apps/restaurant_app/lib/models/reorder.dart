import 'package:flutter/foundation.dart';

enum ReorderStatus {
  pending('Pending', 'Awaiting delivery'),
  received('Received', 'Stock added'),
  cancelled('Cancelled', 'Order cancelled');

  const ReorderStatus(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

/// A purchase order for restocking inventory.
///
/// `supplierId` links to a real `Supplier` record (see `models/supplier.dart`)
/// — this used to be a free-text `supplier` string with no backend
/// equivalent; promoted to a real FK alongside the rest of this module's
/// backend connection.
@immutable
class Reorder {
  const Reorder({
    required this.id,
    required this.storeId,
    required this.inventoryItemId,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.supplierId,
    required this.orderedAt,
    this.expectedAt,
    this.receivedAt,
    this.cancelledAt,
    this.status = ReorderStatus.pending,
    this.notes,
  });

  final String id;
  final String storeId;
  final String inventoryItemId;
  final double quantity;
  final String unit;
  final double unitCost;
  final String supplierId;
  final DateTime orderedAt;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final DateTime? cancelledAt;
  final ReorderStatus status;
  final String? notes;

  double get total => quantity * unitCost;

  Reorder copyWith({
    DateTime? receivedAt,
    DateTime? cancelledAt,
    ReorderStatus? status,
  }) {
    return Reorder(
      id: id,
      storeId: storeId,
      inventoryItemId: inventoryItemId,
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      supplierId: supplierId,
      orderedAt: orderedAt,
      expectedAt: expectedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      notes: notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reorder && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
