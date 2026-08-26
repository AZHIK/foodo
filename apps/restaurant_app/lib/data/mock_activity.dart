import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../models/business_role.dart';
import '../models/staff_member.dart';
import '../widgets/data_page/status_badge.dart';
import 'mock_inventory.dart';

/// Plausible audit-log entries for a staff member.
///
/// Deliberately drawn from the same vocabulary the rest of the app uses —
/// order ids that look like the Sales ledger's, item names lifted from the real
/// inventory — so a member's history reads as this restaurant's history rather
/// than filler.
abstract final class MockActivity {
  /// Seeded per staff id: the same person shows the same history on every
  /// launch, which is what makes the screen feel like stored data.
  static math.Random _randomFor(String staffId) =>
      math.Random(staffId.hashCode & 0x7fffffff);

  static const _minEntries = 6;
  static const _maxEntries = 11;

  static List<ActivityEntry> forStaff(StaffMember member, BusinessRole? role) {
    // A pending invite has no history by definition — the account has never
    // been signed into. Showing invented activity for one would be a lie the
    // UI tells about its own data.
    if (member.isPending) return const [];

    final rand = _randomFor(member.id);
    final builders = _buildersFor(role);
    final entries = <ActivityEntry>[];

    // Anchored to when they were last seen, not to now: an inactive member's
    // log has to stop when they stopped, or "last active 3 months ago" sits
    // next to an entry from this morning.
    var at = member.lastActiveAt ?? member.joinedAt;
    final count = _minEntries + rand.nextInt(_maxEntries - _minEntries + 1);

    for (var i = 0; i < count; i++) {
      // The oldest entry is always the account being created, which gives every
      // timeline a definite beginning rather than fading out mid-scroll.
      final build = i == count - 1 ? _joined : builders[rand.nextInt(builders.length)];

      entries.add(
        build(
          '${member.id}-act-${(count - i).toString().padLeft(2, '0')}',
          i == count - 1 ? member.joinedAt : at,
          rand,
        ),
      );

      at = at.subtract(
        Duration(hours: 1 + rand.nextInt(30), minutes: rand.nextInt(60)),
      );
    }

    return entries;
  }

  /// Which kinds of event a member can plausibly generate, given what their
  /// role is actually allowed to do.
  static List<_EntryBuilder> _buildersFor(BusinessRole? role) {
    final builders = <_EntryBuilder>[_signedIn];

    if (role == null) return builders;

    if (role.hasPosAccess) {
      builders.addAll([_processedOrder, _processedOrder, _openedShift]);
    }
    if (role.has('pos.refund')) builders.add(_refunded);
    if (role.has('inventory.adjust')) {
      builders.addAll([_adjustedStock, _loggedWaste]);
    }
    if (role.has('inventory.edit')) builders.add(_editedItem);
    if (role.has('sales.export')) builders.add(_exportedReport);
    if (role.has('staff.invite')) builders.add(_invitedStaff);

    return builders;
  }

  // -------------------------------------------------------------------
  // Entry builders
  // -------------------------------------------------------------------

  static String _itemName(math.Random rand) =>
      MockInventory.items[rand.nextInt(MockInventory.items.length)].name;

  static ActivityEntry _signedIn(String id, DateTime at, math.Random rand) =>
      ActivityEntry(
        id: id,
        at: at,
        title: 'Signed in',
        detail: 'Terminal ${1 + rand.nextInt(3)} · Riverside',
        icon: Icons.login_rounded,
      );

  static ActivityEntry _openedShift(String id, DateTime at, math.Random rand) =>
      ActivityEntry(
        id: id,
        at: at,
        title: 'Opened a till shift',
        detail: 'Float \$${(150 + rand.nextInt(4) * 50)}.00 counted in',
        icon: Icons.lock_open_rounded,
      );

  static ActivityEntry _processedOrder(
    String id,
    DateTime at,
    math.Random rand,
  ) {
    final total = 12 + rand.nextInt(180) + rand.nextDouble();
    return ActivityEntry(
      id: id,
      at: at,
      title: 'Processed order #${1000 + rand.nextInt(90)}',
      detail: '\$${total.toStringAsFixed(2)} · '
          '${rand.nextBool() ? 'Card' : 'Cash'}',
      icon: Icons.point_of_sale_outlined,
      tone: StatusTone.positive,
    );
  }

  static ActivityEntry _refunded(String id, DateTime at, math.Random rand) {
    final total = 8 + rand.nextInt(60) + rand.nextDouble();
    return ActivityEntry(
      id: id,
      at: at,
      title: 'Refunded order #${1000 + rand.nextInt(90)}',
      detail: '\$${total.toStringAsFixed(2)} returned to card',
      icon: Icons.undo_rounded,
      tone: StatusTone.danger,
    );
  }

  static ActivityEntry _adjustedStock(
    String id,
    DateTime at,
    math.Random rand,
  ) {
    final up = rand.nextBool();
    final qty = 1 + rand.nextInt(50);
    return ActivityEntry(
      id: id,
      at: at,
      title: 'Adjusted stock: ${_itemName(rand)}',
      detail: '${up ? '+' : '−'}$qty · ${up ? 'Restock' : 'Recount'}',
      icon: Icons.tune_rounded,
      tone: StatusTone.info,
    );
  }

  static ActivityEntry _loggedWaste(String id, DateTime at, math.Random rand) =>
      ActivityEntry(
        id: id,
        at: at,
        title: 'Logged waste: ${_itemName(rand)}',
        detail: '${1 + rand.nextInt(8)} units · '
            '${rand.nextBool() ? 'Expired' : 'Prep error'}',
        icon: Icons.delete_sweep_outlined,
        tone: StatusTone.warning,
      );

  static ActivityEntry _editedItem(String id, DateTime at, math.Random rand) =>
      ActivityEntry(
        id: id,
        at: at,
        title: 'Updated item: ${_itemName(rand)}',
        detail: rand.nextBool()
            ? 'Unit cost changed'
            : 'Low stock threshold changed',
        icon: Icons.edit_outlined,
      );

  static ActivityEntry _exportedReport(
    String id,
    DateTime at,
    math.Random rand,
  ) => ActivityEntry(
    id: id,
    at: at,
    title: 'Exported a sales report',
    detail: '${rand.nextBool() ? 'PDF' : 'Excel'} · '
        'last ${rand.nextBool() ? 7 : 30} days',
    icon: Icons.file_download_outlined,
  );

  static ActivityEntry _invitedStaff(String id, DateTime at, math.Random rand) {
    const invitees = ['Tomas Alvarez', 'Ruth Nakamura', 'a new cashier'];
    return ActivityEntry(
      id: id,
      at: at,
      title: 'Sent a staff invite',
      detail: 'To ${invitees[rand.nextInt(invitees.length)]}',
      icon: Icons.person_add_alt_outlined,
      tone: StatusTone.info,
    );
  }

  static ActivityEntry _joined(String id, DateTime at, math.Random rand) =>
      ActivityEntry(
        id: id,
        at: at,
        title: 'Joined the team',
        detail: 'Account created and invite accepted',
        icon: Icons.flag_outlined,
        tone: StatusTone.info,
      );
}

/// Signature every entry builder shares, so [MockActivity] can pick one at
/// random without a switch over event kinds.
typedef _EntryBuilder =
    ActivityEntry Function(String id, DateTime at, math.Random rand);
