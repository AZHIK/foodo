import 'dart:typed_data';

import 'package:flutter/material.dart';

/// What kind of venue this is.
///
/// Recorded rather than inferred: it decides which defaults a future onboarding
/// flow offers (a food truck has no tables, a bakery closes at noon) and prints
/// on nothing, so it can be changed freely.
enum BusinessType {
  restaurant('Restaurant', Icons.restaurant_rounded),
  cafe('Cafe', Icons.local_cafe_rounded),
  foodTruck('Food truck', Icons.airport_shuttle_rounded),
  bakery('Bakery', Icons.bakery_dining_rounded),
  bar('Bar', Icons.local_bar_rounded),
  other('Other', Icons.storefront_rounded);

  const BusinessType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The venue's own identity: who it is, where it is, and how it presents
/// itself on anything a customer sees.
///
/// One object rather than a scatter of individual providers, because these are
/// edited together on one screen and saved together — a half-applied profile
/// (new address, old logo) is not a state the app should be able to reach.
///
/// Operational rules — tax, currency, opening hours — deliberately live in
/// [StoreSettings] instead. Identity and behaviour are edited by different
/// people on different days, and keeping them apart is what lets Store Settings
/// be the single source of truth for a tax rate without also owning the logo.
@immutable
class BusinessProfile {
  const BusinessProfile({
    required this.name,
    this.legalName = '',
    this.type = BusinessType.restaurant,
    this.email = '',
    this.phone = '',
    this.website = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.postcode = '',
    this.country = '',
    this.taxId = '',
    this.receiptFooter = '',
    this.brandColor = const Color(0xFF0B6B57),
    this.logoName,
    this.logoBytes,
  });

  /// Trading name — what the nav header and receipts show.
  final String name;

  /// Registered name, when it differs. Printed on invoices, not receipts.
  final String legalName;

  final BusinessType type;

  final String email;
  final String phone;
  final String website;

  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postcode;
  final String country;

  /// VAT/GST registration number, printed on receipts where required.
  final String taxId;

  /// Free text at the bottom of every receipt.
  final String receiptFooter;

  /// The accent a receipt header and any customer-facing surface is tinted
  /// with. Stored on the profile rather than the theme because it belongs to
  /// the business, not to this terminal's light/dark preference.
  final Color brandColor;

  /// Bytes rather than a path, for the same reason item photos are — the app
  /// runs on web, where `dart:io` is unavailable.
  final String? logoName;
  final Uint8List? logoBytes;

  /// The address as a receipt would print it, blank lines dropped.
  String get formattedAddress => [
    addressLine1,
    addressLine2,
    [city, postcode].where((p) => p.trim().isNotEmpty).join(' '),
    country,
  ].where((line) => line.trim().isNotEmpty).join('\n');

  bool get hasAddress => formattedAddress.isNotEmpty;

  BusinessProfile copyWith({
    String? name,
    String? legalName,
    BusinessType? type,
    String? email,
    String? phone,
    String? website,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
    String? country,
    String? taxId,
    String? receiptFooter,
    Color? brandColor,
    String? logoName,
    Uint8List? logoBytes,
    // `logoBytes: null` cannot mean "remove it" when null already means "leave
    // it alone", so clearing needs its own flag.
    bool clearLogo = false,
  }) {
    return BusinessProfile(
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      type: type ?? this.type,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      taxId: taxId ?? this.taxId,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      brandColor: brandColor ?? this.brandColor,
      logoName: clearLogo ? null : (logoName ?? this.logoName),
      logoBytes: clearLogo ? null : (logoBytes ?? this.logoBytes),
    );
  }

  /// The venue this build ships with.
  static const seed = BusinessProfile(
    name: 'The Copper Fig',
    legalName: 'Copper Fig Hospitality Ltd',
    type: BusinessType.restaurant,
    email: 'hello@copperfig.com',
    phone: '+1 415 555 0100',
    website: 'copperfig.com',
    addressLine1: '84 Riverside Walk',
    city: 'San Francisco',
    postcode: 'CA 94107',
    country: 'United States',
    taxId: 'US-TAX-4471902',
    receiptFooter: 'Thank you for dining with us — see you soon!',
  );
}
