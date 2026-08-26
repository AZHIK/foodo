import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_staff.dart';
import '../models/business_role.dart';
import '../models/table_query.dart';
import 'staff_provider.dart';
import 'table_query_provider.dart';

abstract final class RoleSort {
  static const name = 'roleName';
  static const staffCount = 'roleStaffCount';
  static const permissions = 'rolePermissions';
}

/// The single source of truth for roles.
///
/// The roles table, the role form, the staff table's badges and the invite
/// dialog's role picker all read this one list — editing a role in the form is
/// visible everywhere else on the next frame, with nothing to synchronise.
class RolesNotifier extends Notifier<List<BusinessRole>> {
  @override
  List<BusinessRole> build() => MockStaff.roles;

  void upsert(BusinessRole role) {
    final index = state.indexWhere((r) => r.id == role.id);
    if (index == -1) {
      state = [...state, role];
      return;
    }
    final next = [...state];
    next[index] = role;
    state = next;
  }

  /// Deletes a role, refusing to touch a system one.
  ///
  /// The refusal is the contract rather than an assert: staff records and
  /// reporting both reference the built-in roles by id, so losing one corrupts
  /// data that is expensive to reconstruct. The roles table also disables the
  /// action, but a guard that only holds when the UI remembers to ask is not a
  /// guard.
  void delete(String id) {
    final role = byId(id);
    if (role != null && role.isSystem) return;
    state = state.where((r) => r.id != id).toList();
  }

  /// Copies a role's permissions under a new name, which is how most custom
  /// roles actually get made — "Manager, but without refunds".
  BusinessRole duplicate(String id) {
    final source = state.firstWhere((r) => r.id == id);
    final copy = BusinessRole(
      id: nextId(),
      name: _uniqueName('${source.name} copy'),
      description: source.description,
      // A duplicate is never a system role, however it was made.
      permissionIds: Set.of(source.permissionIds),
    );
    state = [...state, copy];
    return copy;
  }

  BusinessRole? byId(String id) {
    for (final role in state) {
      if (role.id == id) return role;
    }
    return null;
  }

  String nextId() {
    var highest = 0;
    for (final role in state) {
      final n = int.tryParse(role.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    // System roles use word ids ("role-owner"), so the counter starts above
    // them rather than colliding at "role-1".
    return 'role-${(highest + 1).clamp(100, 1 << 30)}';
  }

  /// Appends "2", "3", … until the name is free. Two roles called "Manager
  /// copy" would be indistinguishable in every picker in the app.
  String _uniqueName(String preferred) {
    final taken = {for (final role in state) role.name.toLowerCase()};
    if (!taken.contains(preferred.toLowerCase())) return preferred;

    for (var n = 2; n < 100; n++) {
      final candidate = '$preferred $n';
      if (!taken.contains(candidate.toLowerCase())) return candidate;
    }
    return preferred;
  }
}

final rolesProvider = NotifierProvider<RolesNotifier, List<BusinessRole>>(
  RolesNotifier.new,
);

/// A single role by id. Null once a role has been deleted, which is what lets
/// a detail screen show a "not found" state instead of throwing.
final roleByIdProvider = Provider.family<BusinessRole?, String>((ref, id) {
  for (final role in ref.watch(rolesProvider)) {
    if (role.id == id) return role;
  }
  return null;
});

/// How many staff wear each role, keyed by role id.
///
/// Computed once here rather than by each row counting the staff list itself,
/// which would be quadratic over two lists that both live in memory anyway.
final roleStaffCountsProvider = Provider<Map<String, int>>((ref) {
  final counts = <String, int>{};
  for (final member in ref.watch(staffMembersProvider)) {
    counts[member.roleId] = (counts[member.roleId] ?? 0) + 1;
  }
  return counts;
});

// ---------------------------------------------------------------------------
// Table state
// ---------------------------------------------------------------------------

/// The roles list is inherently short, so it shows every role on one page
/// rather than paginating five rows across two pages.
final rolesQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    const TableQuery(sortField: RoleSort.name, pageSize: 50),
  ),
);

final sortedRolesProvider = Provider<List<BusinessRole>>((ref) {
  final roles = [...ref.watch(rolesProvider)];
  final query = ref.watch(rolesQueryProvider);
  final counts = ref.watch(roleStaffCountsProvider);
  final direction = query.ascending ? 1 : -1;

  roles.sort((a, b) {
    final cmp = switch (query.sortField) {
      RoleSort.staffCount => (counts[a.id] ?? 0).compareTo(counts[b.id] ?? 0),
      RoleSort.permissions => a.permissionCount.compareTo(b.permissionCount),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });

  return roles;
});

final rolesSliceProvider = Provider<PageSlice<BusinessRole>>(
  (ref) => PageSlice.of(
    ref.watch(sortedRolesProvider),
    ref.watch(rolesQueryProvider),
  ),
);

@immutable
class RolesSummary {
  const RolesSummary({
    required this.totalRoles,
    required this.customRoles,
    required this.staffAssigned,
  });

  final int totalRoles;
  final int customRoles;
  final int staffAssigned;
}

final rolesSummaryProvider = Provider<RolesSummary>((ref) {
  final roles = ref.watch(rolesProvider);
  final counts = ref.watch(roleStaffCountsProvider);

  var custom = 0;
  var assigned = 0;
  for (final role in roles) {
    if (!role.isSystem) custom++;
    assigned += counts[role.id] ?? 0;
  }

  return RolesSummary(
    totalRoles: roles.length,
    customRoles: custom,
    staffAssigned: assigned,
  );
});
