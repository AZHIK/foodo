import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';

enum CourierStatus {
  active('activeStatus', 'Active', 'courierAvailable', 'Available for deliveries'),
  inactive('inactiveStatus', 'Inactive', 'courierUnavailable', 'Not available');

  const CourierStatus(
    this.labelKey,
    this.labelDefault,
    this.subtitleKey,
    this.subtitleDefault,
  );
  final String labelKey;
  final String labelDefault;
  final String subtitleKey;
  final String subtitleDefault;

  String get label => L10n.t(labelKey, labelDefault);
  String get subtitle => L10n.t(subtitleKey, subtitleDefault);
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
