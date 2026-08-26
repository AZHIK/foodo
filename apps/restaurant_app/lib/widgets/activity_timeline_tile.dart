import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../utils/formatters.dart';
import 'data_page/status_badge.dart';

/// One event on a vertical timeline: a connector rail, a tinted dot, and the
/// event's title, detail and timestamp beside it.
///
/// Generic over what the event *is* — it renders an [ActivityEntry] and knows
/// nothing about staff, orders or stock. [isFirst] and [isLast] trim the rail
/// so a list of these reads as one continuous line with clean ends rather than
/// a stack of separate tiles.
class ActivityTimelineTile extends StatelessWidget {
  const ActivityTimelineTile({
    super.key,
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
  });

  final ActivityEntry entry;
  final bool isFirst;
  final bool isLast;

  /// Width of the rail column. The dot is centred in it, so the connector and
  /// the marker cannot drift apart at different text scales.
  static const double _railWidth = 34;
  static const double _dotSize = 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;

    final accent = switch (entry.tone) {
      StatusTone.positive => semantic.success,
      StatusTone.warning => semantic.warning,
      StatusTone.danger => semantic.danger,
      StatusTone.info => colors.primary,
      StatusTone.neutral => colors.onSurfaceVariant,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: _Rail(
              accent: accent,
              icon: entry.icon,
              isFirst: isFirst,
              isLast: isLast,
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Padding(
              // Bottom padding rather than a separator between tiles, so the
              // rail runs unbroken behind the gap.
              padding: EdgeInsets.only(bottom: isLast ? 0 : Insets.xl),
              child: _Body(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.accent,
    required this.icon,
    required this.isFirst,
    required this.isLast,
  });

  final Color accent;
  final IconData icon;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final line = context.semantic.hairline;

    return Column(
      children: [
        // The stub above the dot is omitted on the first tile so the line
        // starts at the marker rather than floating above it.
        SizedBox(
          height: Insets.xs,
          child: isFirst ? null : _Connector(color: line),
        ),
        Container(
          height: ActivityTimelineTile._dotSize,
          width: ActivityTimelineTile._dotSize,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 15, color: accent),
        ),
        if (!isLast) Expanded(child: _Connector(color: line)),
      ],
    );
  }
}

/// The vertical rule joining two markers.
///
/// Sizes itself from the constraints it is given rather than declaring a
/// height of `double.infinity`. The tile measures itself with an
/// [IntrinsicHeight], and an infinite intrinsic height inside that throws
/// during layout — a [ColoredBox] with no child reports an intrinsic height of
/// zero and still paints the full flex share it is handed.
class _Connector extends StatelessWidget {
  const _Connector({required this.color});

  final Color color;

  static const double _thickness = 1.5;

  @override
  Widget build(BuildContext context) => Align(
    child: SizedBox(width: _thickness, child: ColoredBox(color: color)),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Detail and timestamp share one muted line rather than each taking their
    // own, which keeps a tile two lines tall at any width.
    //
    // Deliberately no LayoutBuilder anywhere in here: the tile measures itself
    // with an [IntrinsicHeight] to size the rail, and a LayoutBuilder cannot
    // report an intrinsic dimension — it throws during layout rather than
    // degrading. Responsive behaviour in this subtree has to come from
    // wrapping and ellipsis, not from branching on width.
    final meta = [
      ?entry.detail,
      Fmt.relativeDateTime(entry.at),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          meta,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Renders a list of entries as one timeline, wiring up [ActivityTimelineTile]'s
/// first/last flags so callers do not repeat that bookkeeping.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.entries,
    this.emptyState,
  });

  final List<ActivityEntry> entries;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return emptyState ?? const _EmptyTimeline();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          ActivityTimelineTile(
            entry: entries[i],
            isFirst: i == 0,
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 28,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'No activity yet',
            style: context.text.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
