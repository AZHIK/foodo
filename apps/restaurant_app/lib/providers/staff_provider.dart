import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_activity.dart';
import '../data/mock_staff.dart';
import '../database/local_profile_repository.dart';
import '../models/activity_entry.dart';
import '../models/staff_member.dart';
import '../models/table_query.dart';
import 'database_providers.dart';
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

/// The single source of truth for staff.
///
/// The list, the detail screen and the invite dialog all read and write this
/// one notifier — an invite sent from the dialog appears in the table because
/// they are the same list, not because anything was copied across.
class StaffNotifier extends Notifier<List<StaffMember>> {
  @override
  List<StaffMember> build() => MockStaff.members;

  void upsert(StaffMember member) {
    final index = state.indexWhere((m) => m.id == member.id);
    if (index == -1) {
      // Newest first, so an invite just sent is at the top of the list the
      // user is already looking at.
      state = [member, ...state];
      return;
    }
    final next = [...state];
    next[index] = member;
    state = next;
  }

  void remove(String id) => state = state.where((m) => m.id != id).toList();

  void setRole(String id, String roleId) => _update(
    id,
    (member) => member.copyWith(roleId: roleId),
  );

  void setStatus(String id, StaffStatus status) => _update(
    id,
    (member) => member.copyWith(status: status),
  );

  /// Flips active ↔ inactive. A pending invite is left alone: there is no
  /// account yet to deactivate.
  void toggleActive(String id) => _update(id, (member) {
    if (member.isPending) return member;
    return member.copyWith(
      status: member.status == StaffStatus.active
          ? StaffStatus.inactive
          : StaffStatus.active,
    );
  });

  /// Creates a pending member from the invite dialog.
  StaffMember invite({
    required String name,
    required String email,
    required String phone,
    required String roleId,
    String? note,
  }) {
    final member = StaffMember(
      id: nextId(),
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      roleId: roleId,
      status: StaffStatus.pendingInvite,
      // The invite date is what "joined" means until they accept it.
      joinedAt: DateTime.now(),
      inviteNote: note == null || note.trim().isEmpty ? null : note.trim(),
    );

    upsert(member);
    return member;
  }

  String nextId() {
    var highest = 0;
    for (final member in state) {
      final n = int.tryParse(member.id.split('-').last);
      if (n != null && n > highest) highest = n;
    }
    return 'stf-${(highest + 1).toString().padLeft(2, '0')}';
  }

  void _update(String id, StaffMember Function(StaffMember) change) {
    state = [
      for (final member in state)
        if (member.id == id) change(member) else member,
    ];
  }
}

final staffMembersProvider =
    NotifierProvider<StaffNotifier, List<StaffMember>>(StaffNotifier.new);

final staffByIdProvider = Provider.family<StaffMember?, String>((ref, id) {
  for (final member in ref.watch(staffMembersProvider)) {
    if (member.id == id) return member;
  }
  return null;
});

/// Who is signed in at this terminal.
///
/// There is no auth layer yet, so this resolves to the owner — the account a
/// single-terminal install would be running as. It exists so the things that
/// need an actor (a stock movement's "who", an audit entry) ask one provider
/// rather than each hardcoding a name, and swapping in a real session later is
/// a change to this provider alone.
final currentUserProvider = Provider<StaffMember?>((ref) {
  final members = ref.watch(staffMembersProvider);
  if (members.isEmpty) return null;

  for (final member in members) {
    if (member.roleId == MockStaff.ownerRoleId &&
        member.status == StaffStatus.active) {
      return member;
    }
  }
  return members.first;
});

/// The signed-in user's name, or a neutral fallback for an empty roster.
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
        StaffMember(
          id: profile.id as String,
          name: profile.displayName as String,
          email: '',
          phone: '',
          roleId: '',
          status: StaffStatus.active,
          joinedAt: profile.createdAt as DateTime,
        ),
    ];
  } catch (_) {
    return [];
  }
});

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
    if (roleIds.isNotEmpty && !roleIds.contains(member.roleId)) return false;
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
  final members = ref.watch(staffMembersProvider);
  final query = ref.watch(staffQueryProvider);
  final filters = ref.watch(staffFiltersProvider);
  final roles = ref.watch(rolesProvider);
  final search = query.search.trim().toLowerCase();

  String roleName(String roleId) {
    for (final role in roles) {
      if (role.id == roleId) return role.name;
    }
    return '';
  }

  final rows = members.where((member) {
    if (!filters.matches(member)) return false;
    if (search.isEmpty) return true;
    return member.name.toLowerCase().contains(search) ||
        member.email.toLowerCase().contains(search) ||
        roleName(member.roleId).toLowerCase().contains(search);
  }).toList();

  final direction = query.ascending ? 1 : -1;
  rows.sort((a, b) {
    final cmp = switch (query.sortField) {
      StaffSort.role => roleName(a.roleId).compareTo(roleName(b.roleId)),
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

  for (final member in ref.watch(staffMembersProvider)) {
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
// Activity
// ---------------------------------------------------------------------------

/// A staff member's audit log, newest first.
///
/// Generated from the member and their role, so a role change alters what the
/// person is shown to have plausibly been doing.
final staffActivityProvider =
    Provider.family<List<ActivityEntry>, String>((ref, staffId) {
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

final staffPerformanceProvider =
    Provider.family<StaffPerformance, String>((ref, staffId) {
      final member = ref.watch(staffByIdProvider(staffId));
      if (member == null || member.isPending) return StaffPerformance.none;

      final role = ref.watch(roleByIdProvider(member.roleId));
      if (role == null || !role.hasPosAccess) return StaffPerformance.none;

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
