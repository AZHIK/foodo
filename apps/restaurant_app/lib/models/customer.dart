import 'package:flutter/foundation.dart';

/// A customer who has placed orders.
@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.addressLine1,
    required this.createdAt,
    this.lastOrderAt,
    required this.totalOrders,
    required this.totalSpent,
    this.serverId,
    this.syncStatus = 'synced',
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? addressLine1;
  final DateTime createdAt;
  final DateTime? lastOrderAt;
  final int totalOrders;
  final double totalSpent;

  /// Server-acknowledged id once this customer has synced. For a customer
  /// this always equals [id] (the id is client-generated and IS the real
  /// server primary key — see `lib/database/tables/customer_entries.dart`'s
  /// doc comment) — this field exists purely as a "has the server
  /// acknowledged this row?" signal, mirroring `OtherExpense.serverId`, so
  /// `CustomersNotifier.edit`/`delete` can branch the same way.
  final String? serverId;

  /// `pending` | `syncing` | `failed` | `synced`. Demo-mode rows default to
  /// `synced` so existing call sites that don't pass it keep behaving as
  /// before.
  final String syncStatus;

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    bool clearEmail = false,
    String? addressLine1,
    bool clearAddressLine1 = false,
    DateTime? lastOrderAt,
    bool clearLastOrderAt = false,
    int? totalOrders,
    double? totalSpent,
    String? serverId,
    String? syncStatus,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: clearEmail ? null : (email ?? this.email),
      addressLine1:
          clearAddressLine1 ? null : (addressLine1 ?? this.addressLine1),
      createdAt: createdAt,
      lastOrderAt: clearLastOrderAt ? null : (lastOrderAt ?? this.lastOrderAt),
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Customer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
