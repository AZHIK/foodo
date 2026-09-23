import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../theme/dashboard_colors.dart';

/// A numbered row for a "top N" list.
///
/// The rank badge takes its colour from the item's category, so the ordering
/// here and the slices in the donut beside it read as the same data seen two
/// ways rather than two unrelated charts.
class RankedListTile extends StatelessWidget {
  const RankedListTile({
    super.key,
    required this.rank,
    required this.title,
    required this.trailing,
    this.colorIndex = 0,
    this.leadingEmoji,
    this.subtitle,
    this.onTap,
    this.progress,
  });

  /// One-based.
  final int rank;

  final String title;

  /// Right-aligned value — units sold, revenue.
  final String trailing;

  /// Index into the dashboard palette's category colours.
  final int colorIndex;

  final String? leadingEmoji;
  final String? subtitle;
  final VoidCallback? onTap;

  /// 0..1 relative bar under the row. Null hides it (desktop density).
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final family = DashboardPalette.of(context).category(colorIndex);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.sm),
      child: LayoutBuilder(
        builder: (context, constraints) => _row(
          context,
          family: family,
          colors: colors,
          // The emoji is decoration; at this width the name and the count are
          // the two things that have to survive.
          showEmoji: leadingEmoji != null && constraints.maxWidth >= 200,
        ),
      ),
    );

    if (onTap == null) return row;

    // Transparent Material so the ripple paints above the card's own fill
    // rather than behind it.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: row,
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required DashboardColor family,
    required ColorScheme colors,
    required bool showEmoji,
  }) {
    final row = Row(
      children: [
        Container(
          height: 30,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [family.tint, family.tint],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: family.accent.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            AppStrings.rankBadge(rank),
            style: context.text.labelLarge?.copyWith(
              color: family.onTint,
            ),
          ),
        ),
        const SizedBox(width: Insets.md),
        if (showEmoji) ...[
          Container(
            height: 34,
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(leadingEmoji!, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: Insets.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle case final sub!)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: Insets.sm),
        Flexible(
          child: Text(
            trailing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: context.text.titleSmall?.copyWith(
              color: family.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );

    if (progress == null) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor:
                  colors.surfaceContainerHighest.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(family.accent),
            ),
          ),
        ),
      ],
    );
  }
}
