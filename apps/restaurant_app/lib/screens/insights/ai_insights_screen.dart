import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/ai_insight.dart';
import '../../providers/ai_insights_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import '../../widgets/nav_shell_scope.dart';

/// The assistant: observations derived from the business's own data, plus a
/// place to ask for more.
///
/// Every card is generated from live providers, so the advice moves with the
/// stockroom rather than sitting as fixed copy. The ask box is the one part
/// that is not wired to anything — there is no model behind it yet, and it
/// says so rather than pretending.
class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(aiInsightsProvider);
    final prompts = ref.watch(suggestedPromptsProvider);

    return DetailPageScaffold(
      maxContentWidth: 1100,
      header: const _InsightsHeader(),
      sidePanel: [_AskPanel(prompts: prompts)],
      children: [
        for (final insight in insights) _InsightCard(insight: insight),
      ],
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    final pad = Insets.page(context.formFactor);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, Insets.md, pad, Insets.sm),
      child: Row(
        children: [
          const NavMenuButton(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Insights',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Generated from your live stock, sales and waste data',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  insight.category.icon,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    insight.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Flexible(
                  child: StatusBadge(
                    label: insight.priority.label,
                    tone: insight.priority.tone,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            Text(
              insight.body,
              style: context.text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (insight.evidence.isNotEmpty) ...[
              const SizedBox(height: Insets.md),
              // The numbers behind the claim, so the reader can check it
              // rather than take it on trust.
              Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: [
                  for (final fact in insight.evidence)
                    _EvidenceChip(label: fact.label, value: fact.value),
                ],
              ),
            ],
            if (insight.hasAction) ...[
              const SizedBox(height: Insets.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.goNamed(
                    insight.actionRoute!,
                    pathParameters: insight.actionParams,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(
                    insight.actionLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md - 2,
        vertical: Insets.sm - 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AskPanel extends StatefulWidget {
  const _AskPanel({required this.prompts});

  final List<String> prompts;

  @override
  State<_AskPanel> createState() => _AskPanelState();
}

class _AskPanelState extends State<_AskPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    // No model is wired up yet. Saying so is better than a fake reply that
    // would be indistinguishable from a real one until someone relied on it.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ask is not connected to a model yet — the cards on the left are '
          'generated locally from your data.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DetailPanel(
      title: 'Ask about your business',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _ask(),
            decoration: InputDecoration(
              hintText: 'e.g. which supplier costs me the most?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: context.semantic.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
          FilledButton.icon(
            onPressed: _controller.text.trim().isEmpty ? null : _ask,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('Ask'),
          ),
          const SizedBox(height: Insets.lg),
          Text(
            'TRY ASKING',
            style: context.text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Insets.sm),
          for (final prompt in widget.prompts)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: _PromptChip(
                label: prompt,
                onTap: () {
                  _controller.text = prompt;
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(color: context.semantic.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm + 1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Icon(
                Icons.north_east_rounded,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
