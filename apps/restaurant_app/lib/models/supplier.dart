import 'package:flutter/foundation.dart';

/// A vendor a business orders restock inventory from.
///
/// Unlike `Customer`/other synced entities, a supplier has no client-side
/// pending state to track — writes go direct to Inventory Service (no
/// offline outbox, see `suppliers_provider.dart`'s doc comment), so a
/// `Supplier` in memory is always either a real server row or, in demo
/// mode, purely local.
@immutable
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.addressLine1,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? addressLine1;
  final String? notes;
  final DateTime createdAt;

  Supplier copyWith({
    String? name,
    String? phone,
    bool clearPhone = false,
    String? email,
    bool clearEmail = false,
    String? addressLine1,
    bool clearAddressLine1 = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: clearPhone ? null : (phone ?? this.phone),
      email: clearEmail ? null : (email ?? this.email),
      addressLine1: clearAddressLine1 ? null : (addressLine1 ?? this.addressLine1),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Supplier && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
