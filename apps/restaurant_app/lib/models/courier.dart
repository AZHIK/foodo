import 'package:flutter/foundation.dart';

enum CourierStatus {
  active('Active', 'Available for deliveries'),
  inactive('Inactive', 'Not available');

  const CourierStatus(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

/// A delivery courier/driver.
@immutable
class Courier {
  const Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final CourierStatus status;

  Courier copyWith({
    String? name,
    String? phone,
    String? vehicle,
    CourierStatus? status,
  }) {
    return Courier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Courier && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
