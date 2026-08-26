import '../models/business_role.dart';
import '../models/permission.dart';
import '../models/staff_member.dart';

/// In-memory stand-in for a staff/roles service.
///
/// Swap this for an HTTP implementation and only `staff_provider.dart` and
/// `roles_provider.dart` need to change.
abstract final class MockStaff {
  // -------------------------------------------------------------------
  // Roles
  // -------------------------------------------------------------------

  static const ownerRoleId = 'role-owner';
  static const managerRoleId = 'role-manager';
  static const cashierRoleId = 'role-cashier';
  static const kitchenRoleId = 'role-kitchen';
  static const stockRoleId = 'role-stock';

  /// The three system roles plus two custom ones, so the roles table has both
  /// kinds and the "Delete disabled" case is visible without inventing a role.
  static List<BusinessRole> get roles => [
    BusinessRole(
      id: ownerRoleId,
      name: 'Owner',
      description: 'Unrestricted access to every part of the business',
      isSystem: true,
      // Every permission in the catalogue — an owner is defined by having no
      // ceiling, so this stays derived rather than a list that must be
      // extended by hand each time a permission is added.
      permissionIds: {for (final p in AppPermissions.all) p.id},
    ),
    const BusinessRole(
      id: managerRoleId,
      name: 'Manager',
      description: 'Runs the floor day to day, without billing access',
      isSystem: true,
      permissionIds: {
        AppPermissions.posAccess,
        AppPermissions.posDiscount,
        AppPermissions.posRefund,
        AppPermissions.inventoryView,
        AppPermissions.inventoryEdit,
        AppPermissions.inventoryAdjust,
        AppPermissions.salesView,
        AppPermissions.salesExport,
        AppPermissions.reportsView,
        AppPermissions.staffView,
        AppPermissions.staffInvite,
        AppPermissions.settingsStore,
        AppPermissions.settingsTax,
        AppPermissions.settingsDevices,
      },
    ),
    const BusinessRole(
      id: cashierRoleId,
      name: 'Cashier',
      description: 'Takes orders and payments at the till',
      isSystem: true,
      permissionIds: {
        AppPermissions.posAccess,
        AppPermissions.posDiscount,
        AppPermissions.inventoryView,
        AppPermissions.salesView,
        AppPermissions.staffView,
      },
    ),
    const BusinessRole(
      id: kitchenRoleId,
      name: 'Kitchen lead',
      description: 'Owns prep, waste logging and the stockroom count',
      permissionIds: {
        AppPermissions.inventoryView,
        AppPermissions.inventoryEdit,
        AppPermissions.inventoryAdjust,
        AppPermissions.reportsView,
        AppPermissions.staffView,
      },
    ),
    const BusinessRole(
      id: stockRoleId,
      name: 'Stock controller',
      description: 'Purchasing and stock accuracy across all sites',
      permissionIds: {
        AppPermissions.inventoryView,
        AppPermissions.inventoryEdit,
        AppPermissions.inventoryAdjust,
        AppPermissions.inventoryDelete,
        AppPermissions.salesView,
        AppPermissions.reportsView,
      },
    ),
  ];

  // -------------------------------------------------------------------
  // Staff
  // -------------------------------------------------------------------

  /// Anchors every relative timestamp below, so "3 hours ago" stays 3 hours
  /// ago however long the app has been running.
  static final DateTime _now = DateTime.now();

  static DateTime _daysAgo(int days, {int hour = 9, int minute = 0}) {
    final day = _now.subtract(Duration(days: days));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static DateTime _hoursAgo(num hours) =>
      _now.subtract(Duration(minutes: (hours * 60).round()));

  /// First names match the servers in `mock_orders.dart`, so a sale attributed
  /// to "Ava" belongs to a person who actually appears in the staff list.
  static List<StaffMember> get members => [
    StaffMember(
      id: 'stf-01',
      name: 'Ava Mensah',
      email: 'ava@riversidekitchen.com',
      phone: '+1 415 555 0118',
      roleId: ownerRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(892),
      lastActiveAt: _hoursAgo(0.4),
    ),
    StaffMember(
      id: 'stf-02',
      name: 'Marco Ferreira',
      email: 'marco@riversidekitchen.com',
      phone: '+1 415 555 0142',
      roleId: managerRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(614),
      lastActiveAt: _hoursAgo(1.5),
    ),
    StaffMember(
      id: 'stf-03',
      name: 'Priya Raman',
      email: 'priya@riversidekitchen.com',
      phone: '+1 415 555 0177',
      roleId: managerRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(430),
      lastActiveAt: _hoursAgo(3),
    ),
    StaffMember(
      id: 'stf-04',
      name: 'Dan Okoye',
      email: 'dan@riversidekitchen.com',
      phone: '+1 415 555 0163',
      roleId: cashierRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(288),
      lastActiveAt: _hoursAgo(0.2),
    ),
    StaffMember(
      id: 'stf-05',
      name: 'Yuki Tanaka',
      email: 'yuki@riversidekitchen.com',
      phone: '+1 415 555 0195',
      roleId: cashierRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(201),
      lastActiveAt: _hoursAgo(5),
    ),
    StaffMember(
      id: 'stf-06',
      name: 'Sofia Lindqvist',
      email: 'sofia@riversidekitchen.com',
      phone: '+1 415 555 0121',
      roleId: cashierRoleId,
      status: StaffStatus.inactive,
      joinedAt: _daysAgo(377),
      lastActiveAt: _daysAgo(46, hour: 17, minute: 20),
    ),
    StaffMember(
      id: 'stf-07',
      name: 'Noah Adeyemi',
      email: 'noah@riversidekitchen.com',
      phone: '+1 415 555 0134',
      roleId: kitchenRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(512),
      lastActiveAt: _hoursAgo(2.2),
    ),
    StaffMember(
      id: 'stf-08',
      name: 'Lena Vogel',
      email: 'lena@riversidekitchen.com',
      phone: '+1 415 555 0186',
      roleId: stockRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(155),
      lastActiveAt: _hoursAgo(7),
    ),
    StaffMember(
      id: 'stf-09',
      name: 'Tomas Alvarez',
      email: 'tomas.alvarez@gmail.com',
      roleId: cashierRoleId,
      status: StaffStatus.pendingInvite,
      joinedAt: _daysAgo(2, hour: 11, minute: 15),
      inviteNote: 'Welcome aboard — training shift is Thursday at 4pm.',
    ),
    StaffMember(
      id: 'stf-10',
      name: 'Ruth Nakamura',
      email: 'r.nakamura@outlook.com',
      phone: '+1 415 555 0109',
      roleId: kitchenRoleId,
      status: StaffStatus.pendingInvite,
      joinedAt: _daysAgo(5, hour: 16, minute: 40),
    ),
    StaffMember(
      id: 'stf-11',
      name: 'Kofi Boateng',
      email: 'kofi@riversidekitchen.com',
      phone: '+1 415 555 0152',
      roleId: cashierRoleId,
      status: StaffStatus.inactive,
      joinedAt: _daysAgo(268),
      lastActiveAt: _daysAgo(94, hour: 21, minute: 5),
    ),
    StaffMember(
      id: 'stf-12',
      name: 'Ines Duarte',
      email: 'ines@riversidekitchen.com',
      phone: '+1 415 555 0173',
      roleId: managerRoleId,
      status: StaffStatus.active,
      joinedAt: _daysAgo(96),
      lastActiveAt: _hoursAgo(11),
    ),
  ];

  /// Names allowed to appear as the actor on a stock movement — everyone whose
  /// role can actually adjust stock. Keeps the ledger internally consistent
  /// with the permission model rather than attributing a restock to a cashier.
  static List<String> stockHandlerNames(List<BusinessRole> allRoles) {
    final permitted = {
      for (final role in allRoles)
        if (role.has(AppPermissions.inventoryAdjust)) role.id,
    };

    final names = [
      for (final member in members)
        if (permitted.contains(member.roleId) && !member.isPending) member.name,
    ];

    // The ledger has to name someone even if the role data is edited down to
    // nothing, and an empty pool would throw at the first modulo.
    return names.isEmpty ? const ['System'] : names;
  }
}
