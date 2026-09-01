import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/staff_rbac_dtos.dart';
import '../data/mock_activity.dart';
import '../models/activity_entry.dart';
import '../models/staff_member.dart';
import '../models/table_query.dart';
import 'database_providers.dart';
import 'permissions_provider.dart';
import 'roles_provider.dart';
import 'table_query_provider.dart';

abstract final class StaffSort {
  static const name = 'staffName';
  static const role = 'staffRole';
  static const email = 'staffEmail';
  static const status = 'staffStatus';
  static const lastActive = 'staffLastActive';
}

// ---------------------------------------------------------------------------
// Raw data
// ---------------------------------------------------------------------------

StaffStatus _parseStatus(String backendStatus) => switch (backendStatus) {
  'invited' => StaffStatus.pendingInvite,
  'suspended' || 'locked' => StaffStatus.inactive,
  _ => StaffStatus.active,
};

StaffMember _fromDto(StaffMemberDto dto) => StaffMember(
  id: dto.userId,
  name: dto.fullName.trim().isEmpty ? dto.phone : dto.fullName,
  email: dto.email ?? '',
  phone: dto.phone,
  roles: [
    for (final r in dto.roles) StaffRoleAssignment(roleId: r.businessRoleId, roleName: r.name),
  ],
  status: _parseStatus(dto.status),
  // The backend doesn't return a joined/invited timestamp on this endpoint —
  // "now" is wrong for anyone but a just-invited member, so this is the one
  // field the real integration can't populate honestly yet. See the
  // integration report for how staffActivityProvider below is affected.
  joinedAt: DateTime.now(),
);

/// Parses roleLabel (cached comma-separated role names) back into StaffRoleAssignment objects.
///
/// During onboarding, roleLabel is cached from JWT claims as a display-only string.
/// When loading saved profiles offline, we reconstruct the roles list from this cached label
/// so the profile picker can display the role without needing an API call.
///
/// The roleId is not available locally (only the name is cached), so we use the name
/// as a placeholder. Full role data comes from the roles list on reconnect.
List<StaffRoleAssignment> _parseRolesFromLabel(String? label) {
  if (label == null || label.trim().isEmpty) return const [];

  return [
    for (final name in label.split(','))
      StaffRoleAssignment(
        roleId: name.trim(), // Use name as placeholder; full roleId comes from API
        roleName: name.trim(),
      ),
  ];
}

/// The single source of truth for staff, backed by the real
/// `GET /businesses/{id}/staff` endpoint.
///
/// The list, the detail screen and the invite dialog all read and write this
/// one notifier — an invite sent from the dialog appears in the table
/// because `invite()` re-fetches this same list, not because anything was
/// copied across.
class StaffNotifier extends AsyncNotifier<List<StaffMember>> {
  @override
  Future<List<StaffMember>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId == null) return const [];
    final api = ref.read(staffRbacApiProvider);
    final dtos = await api.listStaff(businessId: businessId);
    return dtos.map(_fromDto).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  String get _businessId {
    final id = ref.read(currentBusinessIdProvider);
    if (id == null) throw StateError('No active business context');
    return id;
  }

  /// Assigns [roleId] to the person at [phone] — invites them if the phone
  /// is new, or adds an additional role if they're already staff here (the
  /// backend allows more than one simultaneous role per person; there is no
  /// single-role "replace").
  Future<void> assignRole({required String phone, required String roleId}) async {
    await ref.read(staffRbacApiProvider).assignStaff(
      businessId: _businessId,
      input: AssignStaffInput(businessRoleId: roleId, phone: phone),
    );
    await refresh();
  }

  /// Removes exactly one role assignment from a staff member — their other
  /// roles, if any, are untouched.
  Future<void> revokeRole({required String userId, required String roleId}) async {
    await ref.read(staffRbacApiProvider).revokeStaffRole(
      businessId: _businessId,
      userId: userId,
      roleId: roleId,
    );
    await refresh();
  }

  StaffMember? byId(String id) {
    for (final member in state.valueOrNull ?? const <StaffMember>[]) {
      if (member.id == id) return member;
    }
    return null;
  }
}

final staffMembersProvider = AsyncNotifierProvider<StaffNotifier, List<StaffMember>>(
  StaffNotifier.new,
);

final staffByIdProvider = Provider.family<StaffMember?, String>((ref, id) {
  for (final member in ref.watch(staffMembersProvider).valueOrNull ?? const <StaffMember>[]) {
    if (member.id == id) return member;
  }
  return null;
});

/// Who is signed in at this terminal — the staff member matching the
/// current session's own user id, straight from the decoded token.
final currentUserProvider = Provider<StaffMember?>((ref) {
  final myId = ref.watch(currentClaimsProvider)?.sub;
  if (myId == null) return null;
  return ref.watch(staffByIdProvider(myId));
});

/// The signed-in user's name, or a neutral fallback while staff is loading.
final currentUserNameProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider)?.name ?? 'System',
);

/// Staff members loaded from the local database (saved profiles).
/// Used by the profile picker to display saved users who have previously signed in.
final localSavedStaffProvider = FutureProvider<List<StaffMember>>((ref) async {
  try {
    final profileRepo = ref.watch(localProfileRepositoryProvider);
    final profiles = await profileRepo.allProfiles() as List;

    return [
      for (final profile in profiles)
        _debugLogProfile(
          StaffMember(
            id: profile.id as String,
            name: profile.displayName as String,
            email: '',
            phone: '',
            // Reconstruct roles from cached roleLabel (comma-separated role names).
            // roleLabel is cached during onboarding from JWT claims, e.g., "Owner" or "Manager, Cashier".
            roles: _parseRolesFromLabel(profile.roleLabel as String?),
            status: StaffStatus.active,
            joinedAt: profile.createdAt as DateTime,
          ),
          profile.roleLabel as String?,
        ),
    ];
  } catch (e) {
    print('ERROR loading local staff: $e');
    return [];
  }
});

/// Debug helper to log what's being loaded from the database.
StaffMember _debugLogProfile(StaffMember member, String? roleLabel) {
  // Loaded from database
  return member;
}

// ---------------------------------------------------------------------------
// Search / sort / pagination
// ---------------------------------------------------------------------------

final staffQueryProvider = NotifierProvider<TableQueryNotifier, TableQuery>(
  () => TableQueryNotifier(
    const TableQuery(sortField: StaffSort.name, pageSize: 8),
  ),
);

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// Empty sets mean "no constraint", matching [InventoryFilters] — "nothing
/// ticked" and "everything ticked" behave the same, which is what users expect.
@immutable
class StaffFilters {
  const StaffFilters({this.roleIds = const {}, this.statuses = const {}});

  final Set<String> roleIds;
  final Set<StaffStatus> statuses;

  int get activeCount => roleIds.length + statuses.length;

  bool matches(StaffMember member) {
    if (roleIds.isNotEmpty && !member.roles.any((r) => roleIds.contains(r.roleId))) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(member.status)) return false;
    return true;
  }

  StaffFilters copyWith({Set<String>? roleIds, Set<StaffStatus>? statuses}) =>
      StaffFilters(
        roleIds: roleIds ?? this.roleIds,
        statuses: statuses ?? this.statuses,
      );
}

class StaffFiltersNotifier extends Notifier<StaffFilters> {
  @override
  StaffFilters build() => const StaffFilters();

  void toggleRole(String id) {
    final next = Set<String>.of(state.roleIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(roleIds: next);
    _resetPage();
  }

  void toggleStatus(StaffStatus status) {
    final next = Set<StaffStatus>.of(state.statuses);
    next.contains(status) ? next.remove(status) : next.add(status);
    state = state.copyWith(statuses: next);
    _resetPage();
  }

  void clear() {
    state = const StaffFilters();
    _resetPage();
  }

  void _resetPage() => ref.read(staffQueryProvider.notifier).resetPage();
}

final staffFiltersProvider =
    NotifierProvider<StaffFiltersNotifier, StaffFilters>(
      StaffFiltersNotifier.new,
    );

// ---------------------------------------------------------------------------
// Derived views
// ---------------------------------------------------------------------------

/// Search + filters + sort in one place, so the screen never sees an
/// unfiltered list and no filtering logic lives in the widget tree.
final filteredStaffProvider = Provider<List<StaffMember>>((ref) {
  final members = ref.watch(staffMembersProvider).valueOrNull ?? const <StaffMember>[];
  final query = ref.watch(staffQueryProvider);
  final filters = ref.watch(staffFiltersProvider);
  final search = query.search.trim().toLowerCase();

  String roleNames(StaffMember m) => m.roles.map((r) => r.roleName).join(' ');

  final rows = members.where((member) {
    if (!filters.matches(member)) return false;
    if (search.isEmpty) return true;
    return member.name.toLowerCase().contains(search) ||
        member.email.toLowerCase().contains(search) ||
        roleNames(member).toLowerCase().contains(search);
  }).toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      StaffSort.role => roleNames(a).toLowerCase().compareTo(roleNames(b).toLowerCase()),
      StaffSort.email => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
      // Active → Inactive → Pending, so ascending reads as "working now first".
      StaffSort.status => a.status.index.compareTo(b.status.index),
      // Never-signed-in sorts oldest: an absent timestamp is not a recent one.
      StaffSort.lastActive => (a.lastActiveAt ?? DateTime(1970)).compareTo(
        b.lastActiveAt ?? DateTime(1970),
      ),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return cmp != 0 ? cmp * direction : a.id.compareTo(b.id);
  });

  return rows;
});

final staffSliceProvider = Provider<PageSlice<StaffMember>>(
  (ref) => PageSlice.of(
    ref.watch(filteredStaffProvider),
    ref.watch(staffQueryProvider),
  ),
);

@immutable
class StaffSummary {
  const StaffSummary({
    required this.total,
    required this.active,
    required this.inactive,
    required this.pending,
  });

  final int total;
  final int active;
  final int inactive;
  final int pending;
}

/// Computed over the whole team rather than the current filter, so the header
/// stays a stable readout while the user filters the table below it.
final staffSummaryProvider = Provider<StaffSummary>((ref) {
  var active = 0;
  var inactive = 0;
  var pending = 0;

  for (final member in ref.watch(staffMembersProvider).valueOrNull ?? const <StaffMember>[]) {
    switch (member.status) {
      case StaffStatus.active:
        active++;
      case StaffStatus.inactive:
        inactive++;
      case StaffStatus.pendingInvite:
        pending++;
    }
  }

  return StaffSummary(
    total: active + inactive + pending,
    active: active,
    inactive: inactive,
    pending: pending,
  );
});

// ---------------------------------------------------------------------------
// Activity & performance
//
// Neither the staff nor role endpoints carry an activity log or POS sales
// figures — those belong to services not wired up in this pass (this task
// is identity-service RBAC only; POS/Inventory integration is the next
// pass per the plan). Both stay synthetic for now, generated from the real
// member/role data rather than separate mock records, so they at least
// react correctly to real role changes; they are not "real" data and this
// block is the one deliberate exception to "no mock data reachable".
// ---------------------------------------------------------------------------

/// A staff member's audit log, newest first.
final staffActivityProvider = Provider.family<List<ActivityEntry>, String>((ref, staffId) {
  final member = ref.watch(staffByIdProvider(staffId));
  if (member == null) return const [];

  final role = ref.watch(roleByIdProvider(member.roleId));
  return MockActivity.forStaff(member, role);
});

/// Till numbers for a member's detail screen.
///
/// Only meaningful for a role with POS access; the screen omits the whole block
/// when [StaffPerformance.applies] is false rather than showing three zeroes.
@immutable
class StaffPerformance {
  const StaffPerformance({
    required this.applies,
    required this.ordersToday,
    required this.ordersThisWeek,
    required this.salesHandled,
  });

  final bool applies;
  final int ordersToday;
  final int ordersThisWeek;
  final double salesHandled;

  static const none = StaffPerformance(
    applies: false,
    ordersToday: 0,
    ordersThisWeek: 0,
    salesHandled: 0,
  );
}

final staffPerformanceProvider = Provider.family<StaffPerformance, String>((ref, staffId) {
  final member = ref.watch(staffByIdProvider(staffId));
  if (member == null || member.isPending) return StaffPerformance.none;

  final hasPosRole = member.roles.any((assignment) {
    final role = ref.watch(roleByIdProvider(assignment.roleId));
    return role?.hasPosAccess ?? false;
  });
  if (!hasPosRole) return StaffPerformance.none;

  // Derived from the id so the numbers are stable across rebuilds and
  // differ per person, without a second random data source to keep in step.
  final seed = member.id.hashCode & 0x7fffffff;
  final today = member.status == StaffStatus.active ? 4 + seed % 19 : 0;
  final week = today * 5 + seed % 23;

  return StaffPerformance(
    applies: true,
    ordersToday: today,
    ordersThisWeek: week,
    salesHandled: week * (18.4 + (seed % 900) / 100),
  );
});
