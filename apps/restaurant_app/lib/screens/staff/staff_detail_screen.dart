import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_role.dart';
import '../../models/staff_member.dart';
import '../../providers/roles_provider.dart';
import '../../providers/staff_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/activity_timeline_tile.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import '../../widgets/staff/role_badge.dart';
import 'invite_staff_dialog.dart';

/// One staff member: who they are, what they can do, and what they have done.
///
/// Same structural pattern as Sale Detail — header, main content, side panel —
/// so moving between the two detail screens feels like one app rather than two.
class StaffDetailScreen extends ConsumerWidget {
  const StaffDetailScreen({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(staffByIdProvider(staffId));
    if (member == null) return _NotFound(staffId: staffId);

    final role = ref.watch(roleByIdProvider(member.roleId));
    final activity = ref.watch(staffActivityProvider(staffId));
    final performance = ref.watch(staffPerformanceProvider(staffId));

    return DetailPageScaffold(
      header: _Header(member: member, role: role),
      sidePanel: [
        _ContactPanel(member: member),
        _AccessPanel(member: member, role: role),
      ],
      children: [
        // Omitted entirely for a role without till access — three zeroes would
        // imply a stock controller is bad at selling rather than not doing it.
        if (performance.applies) _PerformanceBlock(performance: performance),
        DetailPanel(
          title: 'Recent activity',
          child: ActivityTimeline(
            entries: activity,
            emptyState: _NoActivity(member: member),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.member, required this.role});

  final StaffMember member;
  final BusinessRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailPageHeader(
      title: member.name,
      subtitle: member.email,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.staffName),
      leading: StaffAvatar(initials: member.initials, role: role, size: 48),
      badges: [
        StatusBadge(
          label: member.status.label,
          tone: member.status.tone,
          icon: member.status.badgeIcon,
          dense: true,
        ),
        RoleBadge(role: role, dense: true),
      ],
      actions: [
        OutlinedButton.icon(
          onPressed: () => showChangeRoleDialog(context, member),
          icon: const Icon(Icons.badge_outlined, size: 18),
          label: const Text('Change role'),
        ),
        _OverflowMenu(member: member),
      ],
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = member.status == StaffStatus.active;

    return PopupMenuButton<String>(
      tooltip: 'More actions',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) => switch (value) {
        'toggle' => _toggleActive(context, ref),
        'resend' => _resend(context),
        'remove' => _confirmRemove(context, ref),
        _ => null,
      },
      itemBuilder: (context) => [
        if (member.isPending)
          PopupMenuItem(
            value: 'resend',
            child: Row(
              children: [
                Icon(
                  Icons.forward_to_inbox_outlined,
                  size: 17,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.md),
                const Text('Resend invite'),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  active
                      ? Icons.person_off_outlined
                      : Icons.person_add_alt_outlined,
                  size: 17,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.md),
                Text(active ? 'Deactivate account' : 'Reactivate account'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(
                Icons.person_remove_outlined,
                size: 17,
                color: context.semantic.danger,
              ),
              const SizedBox(width: Insets.md),
              Text(
                'Remove staff member',
                style: TextStyle(color: context.semantic.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _resend(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('Invite resent to ${member.email}')));

  void _toggleActive(BuildContext context, WidgetRef ref) {
    ref.read(staffMembersProvider.notifier).toggleActive(member.id);

    final nowActive = member.status != StaffStatus.active;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowActive
              ? '${member.name} reactivated'
              : '${member.name} deactivated',
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: const Text(
          'Their account and access will be removed. Sales they processed stay '
          'in the ledger against their name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Leave before the record disappears out from under this screen.
    context.canPop() ? context.pop() : context.goNamed(AppRoute.staffName);
    ref.read(staffMembersProvider.notifier).remove(member.id);

    messenger.showSnackBar(
      SnackBar(content: Text('${member.name} removed')),
    );
  }
}

// ---------------------------------------------------------------------------
// Side panel
// ---------------------------------------------------------------------------

class _ContactPanel extends StatelessWidget {
  const _ContactPanel({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    return DetailPanel(
      title: 'Contact',
      child: LabeledValueGrid(
        maxColumns: 2,
        minColumnWidth: 240,
        children: [
          LabeledValue(
            label: 'Email',
            value: member.email,
            icon: Icons.mail_outline_rounded,
          ),
          LabeledValue(
            label: 'Phone',
            value: member.phone,
            icon: Icons.phone_outlined,
          ),
          LabeledValue(
            label: member.isPending ? 'Invited' : 'Joined',
            value: Fmt.dayMonthTime(member.joinedAt),
            icon: Icons.event_outlined,
          ),
          LabeledValue(
            label: 'Last active',
            value: member.lastActiveAt == null
                ? 'Never signed in'
                : Fmt.relativeDateTime(member.lastActiveAt!),
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }
}

class _AccessPanel extends ConsumerWidget {
  const _AccessPanel({required this.member, required this.role});

  final StaffMember member;
  final BusinessRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return DetailPanel(
      title: 'Access',
      trailing: TextButton(
        onPressed: () => showChangeRoleDialog(context, member),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
          minimumSize: const Size(0, 32),
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Change'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RoleBadge(role: role),
          const SizedBox(height: Insets.sm),
          Text(
            role?.description ?? 'This role no longer exists.',
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (role != null) ...[
            const SizedBox(height: Insets.md),
            Text(
              role!.permissionSummary,
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (member.inviteNote case final note?) ...[
            const SizedBox(height: Insets.lg),
            const Divider(height: 1),
            const SizedBox(height: Insets.lg),
            LabeledValue(
              label: 'Invite message',
              value: note,
              icon: Icons.chat_bubble_outline_rounded,
              maxLines: 5,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Performance
// ---------------------------------------------------------------------------

class _PerformanceBlock extends StatelessWidget {
  const _PerformanceBlock({required this.performance});

  final StaffPerformance performance;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      SummaryMetricCard(
        label: 'Orders today',
        value: '${performance.ordersToday}',
        trend: performance.ordersToday == 0 ? 'Not on shift' : 'On the till',
        icon: Icons.receipt_long_outlined,
      ),
      SummaryMetricCard(
        label: 'Orders this week',
        value: '${performance.ordersThisWeek}',
        trend: 'Last 7 days',
        icon: Icons.date_range_outlined,
      ),
      SummaryMetricCard(
        label: 'Sales handled',
        value: Fmt.moneyCompact(performance.salesHandled),
        trend: 'Last 7 days',
        icon: Icons.payments_outlined,
        accent: context.semantic.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.md;
        // Three across where there is room, otherwise stacked — two of three
        // side by side with one orphaned below reads as a layout accident.
        final columns = constraints.maxWidth >= 640 ? 3 : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _NoActivity extends StatelessWidget {
  const _NoActivity({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
      child: Column(
        children: [
          Icon(
            member.isPending
                ? Icons.mark_email_unread_outlined
                : Icons.history_toggle_off_rounded,
            size: 28,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            member.isPending
                ? 'Nothing yet — this invite has not been accepted'
                : 'No activity recorded',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 36,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(height: Insets.md),
                Text(
                  'Staff member $staffId not found',
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: Insets.lg),
                FilledButton.icon(
                  onPressed: () => context.goNamed(AppRoute.staffName),
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('Back to staff'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
