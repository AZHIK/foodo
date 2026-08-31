import 'package:flutter/foundation.dart';

import '../auth/auth_dtos.dart';

/// Location type from backend.
enum LocationType {
  headOffice('head_office', 'Head Office'),
  restaurantBranch('restaurant_branch', 'Restaurant Branch'),
  kitchen('kitchen', 'Kitchen'),
  warehouse('warehouse', 'Warehouse'),
  farm('farm', 'Farm'),
  depot('depot', 'Depot');

  const LocationType(this.backendValue, this.label);

  final String backendValue;
  final String label;

  static LocationType fromBackend(String value) {
    return values.firstWhere(
      (type) => type.backendValue == value,
      orElse: () => LocationType.restaurantBranch,
    );
  }
}

/// Store status from backend.
enum StoreStatus {
  active,
  inactive,
  suspended;

  bool get isActive => this == StoreStatus.active;

  static StoreStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.name == value,
      orElse: () => StoreStatus.active,
    );
  }
}

/// A physical site the business operates.
///
/// Synced from the backend Store model. All fields mirror the backend schema.
@immutable
class StoreLocation {
  const StoreLocation({
    required this.id,
    required this.businessId,
    required this.name,
    required this.token,
    required this.locationType,
    required this.status,
    required this.countryCode,
    required this.timezone,
    required this.isPrimary,
    this.city,
    this.address,
    this.email,
    this.phone,
    this.latitude,
    this.longitude,
    this.preferredCurrency = 'TZS',
    this.amount,
    this.maxPaymentTimeMinutes,
    this.logo,
    this.offerRetail = true,
    this.offerWholesale = false,
    this.displayPricesInclusiveOfTax = false,
    this.active = true,
    this.isCurrent = false,
    this.staffCount = 0,
  });

  /// Unique identifier from backend.
  final String id;

  /// Parent business ID.
  final String businessId;

  /// Store name.
  final String name;

  /// Unique token identifier.
  final String token;

  /// Location type (head_office, restaurant_branch, kitchen, warehouse, farm, depot).
  final LocationType locationType;

  /// Store status (active, inactive, suspended).
  final StoreStatus status;

  /// City or locality.
  final String? city;

  /// Physical address.
  final String? address;

  /// Country code (ISO 3166-1 alpha-2).
  final String countryCode;

  /// Contact email.
  final String? email;

  /// Contact phone.
  final String? phone;

  /// IANA timezone identifier.
  final String timezone;

  /// Whether this is the primary store.
  final bool isPrimary;

  /// Coordinates (latitude).
  final double? latitude;

  /// Coordinates (longitude).
  final double? longitude;

  /// Preferred currency (ISO 4217 code).
  final String preferredCurrency;

  /// Credit/tab limit for this store.
  final double? amount;

  /// Maximum time allowed to settle a tab, in minutes.
  final int? maxPaymentTimeMinutes;

  /// Logo URL/path from backend.
  final String? logo;

  /// Whether the store offers retail sales.
  final bool offerRetail;

  /// Whether the store offers wholesale sales.
  final bool offerWholesale;

  /// Whether prices are displayed inclusive of tax.
  final bool displayPricesInclusiveOfTax;

  /// Whether the store is currently active/trading (StoreSetting.active).
  /// Distinct from `status` field, which is the Store's lifecycle state.
  final bool active;

  /// The site this terminal is installed at.
  /// Stock transfers move *out* of it, so it is never offered as a destination,
  /// and it cannot be deleted from the terminal standing in it.
  final bool isCurrent;

  /// Headcount based at this site (local calculation, not from backend).
  final int staffCount;

  /// What the location list shows when no manager has been named.
  static const unassignedManager = 'Unassigned';

  /// Computed from status: true if status is active.
  bool get isActive => status.isActive;

  /// Placeholder for manager assignment (not in backend yet).
  String? get managerId => null;

  /// Placeholder for logo file name.
  String? get logoName => null;

  /// The address as a receipt would print it.
  String get formattedAddress => [
    address,
    [city, countryCode].where((p) => (p?.trim().isNotEmpty ?? false)).join(' '),
  ].where((line) => (line?.trim().isNotEmpty ?? false)).join('\n');

  bool get hasAddress => formattedAddress.isNotEmpty;

  StoreLocation copyWith({
    String? id,
    String? businessId,
    String? name,
    String? token,
    LocationType? locationType,
    StoreStatus? status,
    String? city,
    String? address,
    String? countryCode,
    String? email,
    String? phone,
    String? timezone,
    bool? isPrimary,
    double? latitude,
    double? longitude,
    String? preferredCurrency,
    double? amount,
    int? maxPaymentTimeMinutes,
    String? logo,
    bool? offerRetail,
    bool? offerWholesale,
    bool? displayPricesInclusiveOfTax,
    bool? active,
    bool? isCurrent,
    int? staffCount,
  }) {
    return StoreLocation(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      token: token ?? this.token,
      locationType: locationType ?? this.locationType,
      status: status ?? this.status,
      city: city ?? this.city,
      address: address ?? this.address,
      countryCode: countryCode ?? this.countryCode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      isPrimary: isPrimary ?? this.isPrimary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      amount: amount ?? this.amount,
      maxPaymentTimeMinutes: maxPaymentTimeMinutes ?? this.maxPaymentTimeMinutes,
      logo: logo ?? this.logo,
      offerRetail: offerRetail ?? this.offerRetail,
      offerWholesale: offerWholesale ?? this.offerWholesale,
      displayPricesInclusiveOfTax: displayPricesInclusiveOfTax ?? this.displayPricesInclusiveOfTax,
      active: active ?? this.active,
      isCurrent: isCurrent ?? this.isCurrent,
      staffCount: staffCount ?? this.staffCount,
    );
  }

  /// Toggle store status: active → inactive and vice versa.
  StoreLocation toggleStatus() {
    final newStatus = isActive ? StoreStatus.inactive : StoreStatus.active;
    return copyWith(status: newStatus);
  }

  /// Create a StoreLocation from a backend StoreReadDto.
  factory StoreLocation.fromDto(StoreReadDto dto) {
    return StoreLocation(
      id: dto.id,
      businessId: dto.businessId,
      name: dto.name,
      token: dto.token,
      locationType: LocationType.fromBackend(dto.locationType),
      status: StoreStatus.fromString(dto.status),
      city: dto.city,
      address: dto.address,
      countryCode: dto.countryCode,
      timezone: dto.timezone,
      isPrimary: dto.isPrimary,
    );
  }

  /// Create a StoreLocation from store and setting DTOs.
  factory StoreLocation.fromDtos(StoreReadDto store, StoreSettingReadDto? setting) {
    return StoreLocation(
      id: store.id,
      businessId: store.businessId,
      name: store.name,
      token: store.token,
      locationType: LocationType.fromBackend(store.locationType),
      status: StoreStatus.fromString(store.status),
      city: store.city,
      address: store.address,
      countryCode: store.countryCode,
      timezone: store.timezone,
      isPrimary: store.isPrimary,
      email: setting?.email,
      phone: setting?.phone,
      latitude: setting?.latitude,
      longitude: setting?.longitude,
      preferredCurrency: setting?.preferredCurrency ?? 'TZS',
      amount: setting?.amount,
      maxPaymentTimeMinutes: setting?.maxPaymentTimeMinutes,
      logo: setting?.logo,
      offerRetail: setting?.offerRetail ?? true,
      offerWholesale: setting?.offerWholesale ?? false,
      displayPricesInclusiveOfTax: setting?.displayPricesInclusiveOfTax ?? false,
      active: setting?.active ?? true,
    );
  }
}
