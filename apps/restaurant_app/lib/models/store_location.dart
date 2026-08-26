import 'package:flutter/foundation.dart';

/// A physical site the business operates.
///
/// Grown from the two fields the stock transfer dialog needed into the record
/// Store Management edits. The type is the same one the transfer dropdown has
/// always read, so a location added on the management screen is offered as a
/// transfer destination on the next frame with nothing to synchronise.
@immutable
class StoreLocation {
  const StoreLocation({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.managerId,
    this.staffCount = 0,
    this.isActive = true,
    this.isCurrent = false,
  });

  final String id;
  final String name;

  final String address;
  final String phone;

  /// [StaffMember.id] of whoever runs this site, or null when unassigned.
  final String? managerId;

  /// Headcount based at this site.
  ///
  /// A plain number rather than a count derived from the staff list, because
  /// staff records carry no location yet. When they do, this becomes a
  /// provider-computed value and the field goes away — the column above it does
  /// not have to change.
  final int staffCount;

  /// An inactive site keeps its history but is offered nowhere: not as a
  /// transfer destination, not in a report's location filter.
  final bool isActive;

  /// The site this terminal is installed at. Stock transfers move *out* of it,
  /// so it is never offered as a destination, and it cannot be deleted from
  /// the terminal standing in it.
  final bool isCurrent;

  /// What the location list shows when no manager has been named.
  static const unassignedManager = 'Unassigned';

  StoreLocation copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? managerId,
    int? staffCount,
    bool? isActive,
    bool? isCurrent,
    // Same reason [BusinessProfile.clearLogo] exists: null already means
    // "leave it alone", so removing a manager needs its own flag.
    bool clearManager = false,
  }) {
    return StoreLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      managerId: clearManager ? null : (managerId ?? this.managerId),
      staffCount: staffCount ?? this.staffCount,
      isActive: isActive ?? this.isActive,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

/// Stand-in for a store directory service.
abstract final class MockStores {
  /// Manager ids point at [MockStaff.members]; the warehouse deliberately has
  /// none, so the "unassigned" path is exercised by the shipped data.
  static const locations = <StoreLocation>[
    StoreLocation(
      id: 'st-01',
      name: 'Riverside',
      address: '84 Riverside Walk, San Francisco, CA 94107',
      phone: '+1 415 555 0100',
      managerId: 'stf-01',
      staffCount: 9,
      isCurrent: true,
    ),
    StoreLocation(
      id: 'st-02',
      name: 'Harbour Point',
      address: '12 Pier Road, San Francisco, CA 94111',
      phone: '+1 415 555 0142',
      managerId: 'stf-02',
      staffCount: 6,
    ),
    StoreLocation(
      id: 'st-03',
      name: 'Old Town Market',
      address: '301 Market Street, San Francisco, CA 94103',
      phone: '+1 415 555 0177',
      managerId: 'stf-03',
      staffCount: 4,
    ),
    StoreLocation(
      id: 'st-04',
      name: 'Central Warehouse',
      address: '9 Depot Lane, Oakland, CA 94607',
      phone: '+1 510 555 0190',
      staffCount: 2,
    ),
  ];

  static StoreLocation get current =>
      locations.firstWhere((location) => location.isCurrent);

  /// Everywhere stock could be sent from here, straight off the seed data.
  ///
  /// The live app reads `transferTargetsProvider` instead — a location added on
  /// the Store Management screen has to be offered immediately. This stays for
  /// the mock generators, which build fixture history before any provider
  /// exists to read.
  static List<StoreLocation> get transferTargets =>
      locations.where((location) => !location.isCurrent).toList();
}
