import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/ai_insight.dart';
import '../../constants/app_limits.dart';
import '../../constants/app_strings.dart';
import '../../providers/ai_insights_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../data_page/status_badge.dart';

/// The few things the assistant most wants the owner to know, on the screen
/// they open first.
///
/// Reads the same [aiInsightsProvider] the Insights screen does rather than a
/// dashboard-only copy — the point of a highlight is that it is the same
/// finding, seen earlier. What differs is only how many are shown and how much
/// of each: the full screen carries the evidence, this carries the headline
/// and one number.
class InsightHighlights extends ConsumerWidget {
  const InsightHighlights({super.key, this.limit = AppLimits.insightHighlights});

  /// Three fits the width without the cards becoming slivers, and three is
  /// about as many things as anyone acts on before service starts.
  final int limit;

  /// Below this the cards stop having room side by side and stack.
  static const double _sideBySideMin = 760;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(aiInsightsProvider).take(limit).toList();
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 17,
              color: context.colors.primary,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                AppStrings.lookAtToday,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed(AppRoute.insightsName),
              child: const Text(AppStrings.seeAll),
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            // Phones: horizontal snap carousel with a peek of the next card.
            // Three stacked insight cards bury the charts a full screen down;
            // a swipeable row keeps the section one card tall and invites
            // exploration with a thumb.
            if (constraints.maxWidth < _sideBySideMin) {
              return SizedBox(
                height: 212,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  itemCount: insights.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: Insets.md),
                  itemBuilder: (context, i) => SizedBox(
                    width: (constraints.maxWidth * 0.82)
                        .clamp(260.0, 320.0),
                    child: _InsightCard(
                      insight: insights[i],
                      compact: true,
                    ),
                  ),
                ),
              );
            }
            const spacing = Insets.md;
            final columns = insights.length;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final insight in insights)
                  SizedBox(
                    width: width,
                    child: _InsightCard(insight: insight),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, this.compact = false});

  final AiInsight insight;

  /// Carousel mode on phones: tighter padding, 2-line body so the card fits
  /// its fixed carousel height without overflowing.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = switch (insight.priority) {
      InsightPriority.urgent => context.semantic.danger,
      InsightPriority.advisory => context.semantic.warning,
      InsightPriority.informational => colors.primary,
    };

    return Material(
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: context.semantic.hairline),
      ),
      child: InkWell(
        onTap: () => context.goNamed(AppRoute.insightsName),
        child: Stack(
          children: [
            // A colour bar down the leading edge rather than a tinted card:
            // three of these side by side, each fully tinted, would shout over
            // the KPI row above them.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accent),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Insets.lg,
                compact ? Insets.md : Insets.lg,
                Insets.lg,
                compact ? Insets.md : Insets.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(insight.category.icon, size: 15, color: accent),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: Text(
                          insight.category.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.eyebrow.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: insight.priority.label,
                        tone: insight.priority.tone,
                        dense: true,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? Insets.sm : Insets.md),
                  Text(
                    insight.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    insight.body,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  // One piece of evidence, so the card makes a claim and backs
                  // it in the same breath. The rest is on the Insights screen.
                  if (insight.evidence.isNotEmpty) ...[
                    SizedBox(height: compact ? Insets.sm : Insets.md),
                    _EvidenceChip(
                      label: insight.evidence.first.label,
                      value: insight.evidence.first.value,
                      accent: accent,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md - 2,
        vertical: Insets.xs + 1,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            value,
            maxLines: 1,
            style: context.text.labelLarge?.copyWith(
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
