import 'package:flutter/material.dart';

import 'permission.dart';

/// A named set of permissions that staff are assigned to.
@immutable
class BusinessRole {
  const BusinessRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionIds,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final String description;

  /// Ids from [AppPermissions]. A set because order carries no meaning and
  /// membership is the only question ever asked of it.
  final Set<String> permissionIds;

  /// System roles ship with the product. They can be edited but not renamed or
  /// deleted — staff and reporting both reference them by name.
  final bool isSystem;

  /// Resolved against the catalogue, so a retired permission id left over in
  /// the data never inflates the count shown in the table.
  int get permissionCount => AppPermissions.resolve(permissionIds).length;

  bool has(String permissionId) => permissionIds.contains(permissionId);

  /// Whether this role works a till. Drives the performance block on a staff
  /// member's detail screen — a stock controller has no orders to summarise.
  bool get hasPosAccess => has(AppPermissions.posAccess);

  /// "12 of 18 permissions", the table's at-a-glance summary.
  String get permissionSummary =>
      '$permissionCount of ${AppPermissions.count} permissions';

  BusinessRole copyWith({
    String? name,
    String? description,
    Set<String>? permissionIds,
  }) {
    return BusinessRole(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissionIds: permissionIds ?? this.permissionIds,
      isSystem: isSystem,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BusinessRole && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
