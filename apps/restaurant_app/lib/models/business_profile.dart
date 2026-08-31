import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../auth/auth_dtos.dart';

/// Business types from backend.
enum BusinessType {
  restaurant('Restaurant', Icons.restaurant_rounded, 'restaurant'),
  supplier('Supplier', Icons.local_shipping_rounded, 'supplier'),
  farmer('Farmer', Icons.agriculture_rounded, 'farmer'),
  distributor('Distributor', Icons.warehouse_rounded, 'distributor'),
  platformOperator('Platform Operator', Icons.public_rounded, 'platform_operator'),
  other('Other', Icons.storefront_rounded, 'restaurant'); // default fallback

  const BusinessType(this.label, this.icon, this.backendValue);

  final String label;
  final IconData icon;
  final String backendValue;

  static BusinessType fromBackend(String value) {
    return values.firstWhere(
      (type) => type.backendValue == value,
      orElse: () => BusinessType.restaurant,
    );
  }
}

/// Business status from backend.
enum BusinessStatus {
  active,
  inactive,
  suspended;

  bool get isActive => this == BusinessStatus.active;
  bool get isInactive => this == BusinessStatus.inactive;
  bool get isSuspended => this == BusinessStatus.suspended;

  static BusinessStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.name == value,
      orElse: () => BusinessStatus.active,
    );
  }
}

/// The venue's own identity: who it is, where it is, and how it presents
/// itself on anything a customer sees.
///
/// Synced from the backend Business model. All fields mirror the backend schema.
@immutable
class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.name,
    required this.businessType,
    required this.status,
    required this.countryCode,
    required this.timezone,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.taxId,
    this.registrationNumber,
    this.cuisineType,
    this.logo,
    this.licenseDocumentUrl,
    this.brandColor = const Color(0xFF0B6B57),
    this.logoBytes,
  });

  /// Unique identifier from backend.
  final String id;

  /// Trading name.
  final String name;

  /// Business type (restaurant, supplier, farmer, etc).
  final BusinessType businessType;

  /// Business status (active, inactive, suspended).
  final BusinessStatus status;

  /// Contact email.
  final String? email;

  /// Contact phone.
  final String? phone;

  /// Physical address.
  final String? address;

  /// City or locality.
  final String? city;

  /// Country code (ISO 3166-1 alpha-2).
  final String countryCode;

  /// IANA timezone identifier.
  final String timezone;

  /// VAT/GST registration number.
  final String? taxId;

  /// Business registration number.
  final String? registrationNumber;

  /// Cuisine type (for restaurants).
  final String? cuisineType;

  /// Logo URL/path from backend.
  final String? logo;

  /// License document URL/path from backend.
  final String? licenseDocumentUrl;

  /// Brand color for receipts and UI.
  final Color brandColor;

  /// Logo bytes for local editing.
  final Uint8List? logoBytes;

  /// The address as a receipt would print it.
  String get formattedAddress => [
    address,
    [city, countryCode].where((p) => (p?.trim().isNotEmpty ?? false)).join(' '),
  ].where((line) => (line?.trim().isNotEmpty ?? false)).join('\n');

  bool get hasAddress => formattedAddress.isNotEmpty;

  BusinessProfile copyWith({
    String? id,
    String? name,
    BusinessType? businessType,
    BusinessStatus? status,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? countryCode,
    String? timezone,
    String? taxId,
    String? registrationNumber,
    String? cuisineType,
    String? logo,
    String? licenseDocumentUrl,
    Color? brandColor,
    Uint8List? logoBytes,
    bool clearLogoBytes = false,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      status: status ?? this.status,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      taxId: taxId ?? this.taxId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      cuisineType: cuisineType ?? this.cuisineType,
      logo: logo ?? this.logo,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      brandColor: brandColor ?? this.brandColor,
      logoBytes: clearLogoBytes ? null : (logoBytes ?? this.logoBytes),
    );
  }

  /// Create a BusinessProfile from a backend BusinessReadDto.
  factory BusinessProfile.fromDto(BusinessReadDto dto) {
    return BusinessProfile(
      id: dto.id,
      name: dto.name,
      businessType: BusinessType.fromBackend(dto.businessType),
      status: BusinessStatus.fromString(dto.status),
      email: dto.email,
      phone: dto.phone,
      address: dto.address,
      city: dto.city,
      countryCode: dto.countryCode,
      timezone: dto.timezone,
      taxId: dto.taxId,
      registrationNumber: dto.registrationNumber,
      cuisineType: dto.cuisineType,
      logo: dto.logo,
      licenseDocumentUrl: dto.licenseDocumentUrl,
    );
  }
}
