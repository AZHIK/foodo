import '../models/business_role.dart';
import '../models/permission.dart';
import '../models/staff_member.dart';

/// In-memory stand-in for a staff/roles service.
///
/// The real staff/roles screens (`staff_provider.dart`, `roles_provider.dart`)
/// no longer read this — they call the real identity-service endpoints. This
/// stays in place only because inventory's mock stock-movement generator
/// (`mock_stock_movements.dart`) still needs a plausible staff/role roster to
/// attribute adjustments to — that area hasn't been integrated with a real
/// backend yet (POS/Inventory integration is a separate, later pass).
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
      isProtected: true,
      // Every permission in the catalogue — an owner is defined by having no
      // ceiling, so this stays derived rather than a list that must be
      // extended by hand each time a permission is added.
      permissionIds: {for (final p in AppPermissions.all) p.id},
    ),
    const BusinessRole(
      id: managerRoleId,
      name: 'Manager',
      description: 'Runs the floor day to day, without billing access',
      isProtected: true,
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
        AppPermissions.staffAssign,
        AppPermissions.settingsStore,
        AppPermissions.settingsTax,
        AppPermissions.settingsDevices,
      },
    ),
    const BusinessRole(
      id: cashierRoleId,
      name: 'Cashier',
      description: 'Takes orders and payments at the till',
      isProtected: true,
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

  static const _ownerRole = StaffRoleAssignment(roleId: ownerRoleId, roleName: 'Owner');
  static const _managerRole = StaffRoleAssignment(roleId: managerRoleId, roleName: 'Manager');
  static const _cashierRole = StaffRoleAssignment(roleId: cashierRoleId, roleName: 'Cashier');
  static const _kitchenRole = StaffRoleAssignment(roleId: kitchenRoleId, roleName: 'Kitchen lead');
  static const _stockRole = StaffRoleAssignment(
    roleId: stockRoleId,
    roleName: 'Stock controller',
  );

  /// First names match the servers in `mock_orders.dart`, so a sale attributed
  /// to "Ava" belongs to a person who actually appears in the staff list.
  static List<StaffMember> get members => [
    StaffMember(
      id: 'stf-01',
      name: 'Ava Mensah',
      email: 'ava@riversidekitchen.com',
      phone: '+1 415 555 0118',
      roles: const [_ownerRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(892),
      lastActiveAt: _hoursAgo(0.4),
    ),
    StaffMember(
      id: 'stf-02',
      name: 'Marco Ferreira',
      email: 'marco@riversidekitchen.com',
      phone: '+1 415 555 0142',
      roles: const [_managerRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(614),
      lastActiveAt: _hoursAgo(1.5),
    ),
    StaffMember(
      id: 'stf-03',
      name: 'Priya Raman',
      email: 'priya@riversidekitchen.com',
      phone: '+1 415 555 0177',
      roles: const [_managerRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(430),
      lastActiveAt: _hoursAgo(3),
    ),
    StaffMember(
      id: 'stf-04',
      name: 'Dan Okoye',
      email: 'dan@riversidekitchen.com',
      phone: '+1 415 555 0163',
      roles: const [_cashierRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(288),
      lastActiveAt: _hoursAgo(0.2),
    ),
    StaffMember(
      id: 'stf-05',
      name: 'Yuki Tanaka',
      email: 'yuki@riversidekitchen.com',
      phone: '+1 415 555 0195',
      roles: const [_cashierRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(201),
      lastActiveAt: _hoursAgo(5),
    ),
    StaffMember(
      id: 'stf-06',
      name: 'Sofia Lindqvist',
      email: 'sofia@riversidekitchen.com',
      phone: '+1 415 555 0121',
      roles: const [_cashierRole],
      status: StaffStatus.inactive,
      joinedAt: _daysAgo(377),
      lastActiveAt: _daysAgo(46, hour: 17, minute: 20),
    ),
    StaffMember(
      id: 'stf-07',
      name: 'Noah Adeyemi',
      email: 'noah@riversidekitchen.com',
      phone: '+1 415 555 0134',
      roles: const [_kitchenRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(512),
      lastActiveAt: _hoursAgo(2.2),
    ),
    StaffMember(
      id: 'stf-08',
      name: 'Lena Vogel',
      email: 'lena@riversidekitchen.com',
      phone: '+1 415 555 0186',
      roles: const [_stockRole],
      status: StaffStatus.active,
      joinedAt: _daysAgo(155),
      lastActiveAt: _hoursAgo(7),
    ),
    StaffMember(
      id: 'stf-09',
      name: 'Tomas Alvarez',
      email: 'tomas.alvarez@gmail.com',
      roles: const [_cashierRole],
      status: StaffStatus.pendingInvite,
      joinedAt: _daysAgo(2, hour: 11, minute: 15),
      inviteNote: 'Welcome aboard — training shift is Thursday at 4pm.',
    ),
    StaffMember(
      id: 'stf-10',
      name: 'Ruth Nakamura',
      email: 'r.nakamura@outlook.com',
      phone: '+1 415 555 0109',
      roles: const [_kitchenRole],
      status: StaffStatus.pendingInvite,
      joinedAt: _daysAgo(5, hour: 16, minute: 40),
    ),
    StaffMember(
      id: 'stf-11',
      name: 'Kofi Boateng',
      email: 'kofi@riversidekitchen.com',
      phone: '+1 415 555 0152',
      roles: const [_cashierRole],
      status: StaffStatus.inactive,
      joinedAt: _daysAgo(268),
      lastActiveAt: _daysAgo(94, hour: 21, minute: 5),
    ),
    StaffMember(
      id: 'stf-12',
      name: 'Ines Duarte',
      email: 'ines@riversidekitchen.com',
      phone: '+1 415 555 0173',
      roles: const [_managerRole],
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
        if (member.roles.any((r) => permitted.contains(r.roleId)) && !member.isPending)
          member.name,
    ];

    // The ledger has to name someone even if the role data is edited down to
    // nothing, and an empty pool would throw at the first modulo.
    return names.isEmpty ? const ['System'] : names;
  }
}
