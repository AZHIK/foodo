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
@immutable
class Reorder {
  const Reorder({
    required this.id,
    required this.inventoryItemId,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.supplier,
    required this.orderedAt,
    this.expectedAt,
    this.receivedAt,
    this.status = ReorderStatus.pending,
    this.notes,
  });

  final String id;
  final String inventoryItemId;
  final int quantity;
  final String unit;
  final double unitCost;
  final String supplier;
  final DateTime orderedAt;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final ReorderStatus status;
  final String? notes;

  double get total => quantity * unitCost;

  Reorder copyWith({
    int? quantity,
    DateTime? expectedAt,
    DateTime? receivedAt,
    ReorderStatus? status,
    String? notes,
  }) {
    return Reorder(
      id: id,
      inventoryItemId: inventoryItemId,
      quantity: quantity ?? this.quantity,
      unit: unit,
      unitCost: unitCost,
      supplier: supplier,
      orderedAt: orderedAt,
      expectedAt: expectedAt ?? this.expectedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reorder && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
