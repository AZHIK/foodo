import 'package:flutter/material.dart';

import '../widgets/data_page/status_badge.dart';

/// Where a staff account stands.
enum StaffStatus {
  active('Active'),
  inactive('Inactive'),
  pendingInvite('Pending invite');

  const StaffStatus(this.label);
  final String label;

  StatusTone get tone => switch (this) {
    StaffStatus.active => StatusTone.positive,
    StaffStatus.inactive => StatusTone.neutral,
    StaffStatus.pendingInvite => StatusTone.warning,
  };

  IconData get badgeIcon => switch (this) {
    StaffStatus.active => Icons.check_circle_rounded,
    StaffStatus.inactive => Icons.pause_circle_outline_rounded,
    StaffStatus.pendingInvite => Icons.mark_email_unread_outlined,
  };
}

/// A person with access to the business.
@immutable
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    required this.status,
    required this.joinedAt,
    this.phone = '',
    this.lastActiveAt,
    this.inviteNote,
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  /// References [BusinessRole.id]. Held as an id rather than an embedded role
  /// so editing a role updates every member wearing it, with no copies to sync.
  final String roleId;

  final StaffStatus status;

  /// When they joined, or when the invite was sent for a pending member.
  final DateTime joinedAt;

  /// Null for a member who has never signed in — a pending invite.
  final DateTime? lastActiveAt;

  /// Personal message sent with the invite. Kept so a pending member's detail
  /// screen can show what they were told.
  final String? inviteNote;

  bool get isPending => status == StaffStatus.pendingInvite;

  /// Up to two letters for the avatar circle. Falls back to "?" rather than
  /// throwing on a name that is somehow empty.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final only = parts.first;
      return (only.length <= 2 ? only : only.substring(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  StaffMember copyWith({
    String? name,
    String? email,
    String? phone,
    String? roleId,
    StaffStatus? status,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    String? inviteNote,
  }) {
    return StaffMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      inviteNote: inviteNote ?? this.inviteNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StaffMember && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
