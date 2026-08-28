import 'package:flutter/material.dart';

/// One thing a role can be allowed to do.
///
/// Identified by a stable dotted string rather than an enum value, because a
/// real backend hands these over as strings and a custom role saved today has
/// to still resolve after the catalogue grows tomorrow.
@immutable
class Permission {
  const Permission({
    required this.id,
    required this.label,
    required this.description,
  });

  /// e.g. `inventory.adjust`. Stored on the role.
  final String id;

  final String label;

  /// One line under the toggle in the role form, so the person granting a
  /// permission does not have to infer its blast radius from four words.
  final String description;
}

/// A related set of permissions, rendered as one collapsible section.
@immutable
class PermissionGroup {
  const PermissionGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.permissions,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<Permission> permissions;

  List<String> get permissionIds => [for (final p in permissions) p.id];
}

/// The permission catalogue.
///
/// The single source of truth for what a role *can* grant. The role form
/// renders it, the roles table counts against it, and the invite dialog reads
/// labels out of it — none of them hold a list of their own.
///
/// Every id here is a real `PermissionCode` value from the identity-service
/// backend (`app/core/permission_codes.py`) — this used to be an invented
/// catalogue that only accidentally overlapped the backend on 3 of 18
/// entries; every id below either matches a code an endpoint actually
/// enforces today, or one added specifically so this editor has something
/// real to assign (POS/Inventory extras, Sales & Reports, Settings — all
/// unenforced until a future service checks them, same as the backend's own
/// `procurement.*`/`ai.*` codes being defined ahead of their service).
///
/// The Staff Management group deliberately does *not* invent parallel
/// `staff.invite`/`staff.roles`-style ids: the real staff/role endpoints
/// check `user_business_roles.*`/`business_roles.*` specifically, so this
/// group uses those directly — a toggle that doesn't match what the backend
/// actually checks would grant nothing.
abstract final class AppPermissions {
  /// Permissions that let a staff member work a till. A role holding this
  /// gets the sales performance block on their detail screen.
  static const posAccess = 'pos.write';
  static const posDiscount = 'pos.discount';
  static const posRefund = 'pos.refund';

  static const inventoryView = 'inventory.view';
  static const inventoryEdit = 'inventory.edit';
  static const inventoryAdjust = 'inventory.adjust';
  static const inventoryDelete = 'inventory.delete';

  static const salesView = 'sales.view';
  static const salesExport = 'sales.export';
  static const reportsView = 'reports.view';

  static const rolesView = 'business_roles.view';
  static const rolesCreate = 'business_roles.create';
  static const rolesUpdate = 'business_roles.update';
  static const rolesDelete = 'business_roles.delete';
  static const rolesManagePermissions = 'business_roles.manage_permissions';
  static const staffView = 'user_business_roles.view';
  static const staffAssign = 'user_business_roles.assign';
  static const staffRevoke = 'user_business_roles.revoke';

  static const settingsStore = 'settings.store';
  static const settingsTax = 'settings.tax';
  static const settingsDevices = 'settings.devices';
  static const settingsBilling = 'settings.billing';

  static const groups = <PermissionGroup>[
    PermissionGroup(
      id: 'pos',
      label: 'Point of Sale',
      icon: Icons.point_of_sale_outlined,
      permissions: [
        Permission(
          id: posAccess,
          label: 'Open the till',
          description: 'Take orders and process payments',
        ),
        Permission(
          id: posDiscount,
          label: 'Apply discounts',
          description: 'Reduce a ticket total before payment',
        ),
        Permission(
          id: posRefund,
          label: 'Process refunds',
          description: 'Return money against a completed sale',
        ),
      ],
    ),
    PermissionGroup(
      id: 'inventory',
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      permissions: [
        Permission(
          id: inventoryView,
          label: 'View items',
          description: 'See stock levels and item details',
        ),
        Permission(
          id: inventoryEdit,
          label: 'Add & edit items',
          description: 'Create items and change costs or thresholds',
        ),
        Permission(
          id: inventoryAdjust,
          label: 'Adjust stock',
          description: 'Record restocks, waste and transfers',
        ),
        Permission(
          id: inventoryDelete,
          label: 'Delete items',
          description: 'Permanently remove an item and its history',
        ),
      ],
    ),
    PermissionGroup(
      id: 'sales',
      label: 'Sales & Reports',
      icon: Icons.receipt_long_outlined,
      permissions: [
        Permission(
          id: salesView,
          label: 'View sales',
          description: 'Browse the order ledger and receipts',
        ),
        Permission(
          id: salesExport,
          label: 'Export sales data',
          description: 'Download the ledger as PDF or Excel',
        ),
        Permission(
          id: reportsView,
          label: 'View reports',
          description: 'Takings, item mix and staff performance',
        ),
      ],
    ),
    PermissionGroup(
      id: 'staff',
      label: 'Staff Management',
      icon: Icons.groups_outlined,
      permissions: [
        Permission(
          id: staffView,
          label: 'View staff',
          description: 'See the team list and member profiles',
        ),
        Permission(
          id: staffAssign,
          label: 'Invite & assign staff',
          description: 'Send an invite and assign a role',
        ),
        Permission(
          id: staffRevoke,
          label: 'Remove staff roles',
          description: 'Revoke a role assignment from a member',
        ),
        Permission(
          id: rolesView,
          label: 'View roles',
          description: 'See custom roles and what they can do',
        ),
        Permission(
          id: rolesCreate,
          label: 'Create roles',
          description: 'Define a new custom role',
        ),
        Permission(
          id: rolesUpdate,
          label: 'Edit roles',
          description: 'Rename or redescribe an existing role',
        ),
        Permission(
          id: rolesDelete,
          label: 'Delete roles',
          description: 'Remove a custom role with no staff assigned',
        ),
        Permission(
          id: rolesManagePermissions,
          label: 'Manage role permissions',
          description: "Change what a role's toggles grant",
        ),
      ],
    ),
    PermissionGroup(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
      permissions: [
        Permission(
          id: settingsStore,
          label: 'Store profile',
          description: 'Name, address and opening hours',
        ),
        Permission(
          id: settingsTax,
          label: 'Tax & pricing rules',
          description: 'Tax rates and service charges',
        ),
        Permission(
          id: settingsDevices,
          label: 'Devices & printers',
          description: 'Pair terminals and receipt printers',
        ),
        Permission(
          id: settingsBilling,
          label: 'Billing & subscription',
          description: 'Payment method and plan changes',
        ),
      ],
    ),
  ];

  /// Every permission, flattened. Used for "12 of 18" style counts.
  static List<Permission> get all => [
    for (final group in groups) ...group.permissions,
  ];

  static int get count => all.length;

  static Permission? byId(String id) {
    for (final group in groups) {
      for (final permission in group.permissions) {
        if (permission.id == id) return permission;
      }
    }
    return null;
  }

  static String labelFor(String id) => byId(id)?.label ?? id;

  /// Ids that actually exist in the catalogue, in catalogue order.
  ///
  /// A stored role can name a permission that has since been retired; filtering
  /// through this keeps a stale id from being counted or rendered.
  static List<String> resolve(Set<String> ids) => [
    for (final permission in all)
      if (ids.contains(permission.id)) permission.id,
  ];
}
