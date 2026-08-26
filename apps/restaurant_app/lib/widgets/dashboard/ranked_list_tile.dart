import 'package:flutter/material.dart';

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
    return Row(
        children: [
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: family.tint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: context.text.labelMedium?.copyWith(
                color: family.onTint,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: Insets.md),
          if (showEmoji) ...[
            Text(leadingEmoji!, style: const TextStyle(fontSize: 18)),
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
                if (subtitle case final sub?)
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
          // Flexible, not a bare Text: "11 sold" is wide enough to push the
          // row past its card in a narrow side column, and the count is worth
          // ellipsising rather than overflowing.
          Flexible(
            child: Text(
              trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: family.accent,
              ),
            ),
          ),
        ],
    );
  }
}
