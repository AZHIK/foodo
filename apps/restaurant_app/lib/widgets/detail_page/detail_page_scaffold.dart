import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// The shared skeleton for every detail screen: a pinned header, a main
/// column, and an optional side panel that becomes a stacked section on mobile.
///
/// The counterpart to [DataPageScaffold] one level down — a list page fills in
/// metrics, a toolbar and a table; a detail page fills in a header, body
/// sections and panel sections, and writes no layout of its own.
class DetailPageScaffold extends StatelessWidget {
  const DetailPageScaffold({
    super.key,
    required this.header,
    required this.children,
    this.sidePanel = const [],
    this.maxContentWidth = 1180,
    this.sideFirstOnMobile = true,
  });

  /// Usually a [DetailPageHeader]. Pinned above the scrolling body so a long
  /// history cannot scroll the back button off the screen.
  final Widget header;

  /// The main column: the sections this screen is actually about.
  final List<Widget> children;

  /// Supporting sections. Beside the content on tablet and desktop, folded into
  /// the single column on mobile.
  final List<Widget> sidePanel;

  /// Detail content stops widening past this. A stock ledger stretched across
  /// a 1920px terminal is harder to read across, not easier.
  final double maxContentWidth;

  /// Whether the panel comes before the main content once stacked. Contact
  /// details usually should; a wide reference table usually should not.
  final bool sideFirstOnMobile;

  /// Fixed width of the side column. Matches the POS order panel, so the app
  /// has one panel width rather than several near-misses.
  static const double panelWidth = 320;

  /// Below this the two columns stop working and the panel folds under the
  /// content, regardless of the window's own form factor — the body can be
  /// narrower than the window when a rail is taking its share.
  static const double _twoColumnMin = 900;

  @override
  Widget build(BuildContext context) {
    final pad = Insets.page(context.formFactor);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumn =
                      sidePanel.isNotEmpty &&
                      constraints.maxWidth >= _twoColumnMin;

                  return ListView(
                    padding: EdgeInsets.fromLTRB(pad, Insets.sm, pad, pad),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: twoColumn
                              ? _twoColumnBody()
                              : _stackedBody(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _twoColumnBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _column(children)),
        const SizedBox(width: Insets.xl),
        SizedBox(width: panelWidth, child: _column(sidePanel)),
      ],
    );
  }

  Widget _stackedBody() {
    final blocks = sideFirstOnMobile
        ? [...sidePanel, ...children]
        : [...children, ...sidePanel];
    return _column(blocks);
  }

  /// Sections separated by one consistent gap, so no caller has to remember to
  /// put a SizedBox between two panels.
  static Widget _column(List<Widget> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: Insets.lg),
          sections[i],
        ],
      ],
    );
  }
}

/// The header every detail screen shares: back button, an optional leading
/// thumbnail, title and subtitle, status badges, and actions.
///
/// Actions sit inline on a wide header and wrap beneath it on a narrow one,
/// which is what keeps a three-button header from crushing the title at 360px.
class DetailPageHeader extends StatelessWidget {
  const DetailPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.leading,
    this.badges = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;

  /// Runs instead of a plain pop — a deep link can land on a detail screen with
  /// nothing to pop, so every caller supplies a fallback destination.
  final VoidCallback onBack;

  /// A thumbnail or avatar between the back button and the title.
  final Widget? leading;

  final List<Widget> badges;
  final List<Widget> actions;

  /// Below this the title and a row of actions stop coexisting on one line.
  static const double _inlineActionsMin = 720;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pad = Insets.page(context.formFactor);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.headlineSmall,
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
        if (badges.isNotEmpty) ...[
          const SizedBox(height: Insets.sm),
          Wrap(spacing: Insets.sm, runSpacing: Insets.xs, children: badges),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(pad - Insets.sm, Insets.md, pad, Insets.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inline =
              actions.isNotEmpty && constraints.maxWidth >= _inlineActionsMin;

          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(onPressed: onBack),
              if (leading != null) ...[
                leading!,
                const SizedBox(width: Insets.md),
              ],
              Expanded(child: titleBlock),
            ],
          );

          final actionBar = Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            alignment: inline ? WrapAlignment.end : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          );

          if (inline) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: Insets.lg),
                Flexible(child: actionBar),
              ],
            );
          }

          if (actions.isEmpty) return identity;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: Insets.md),
              // Indented to clear the back button, so the actions line up with
              // the title rather than the chevron.
              Padding(
                padding: const EdgeInsets.only(left: Insets.sm),
                child: actionBar,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A titled card, the unit every detail screen is built from.
///
/// Generalised from the Sale Detail receipt panels so Item Detail and Staff
/// Detail inherit the same border, radius and heading treatment for free.
class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(Insets.lg),
  });

  final String title;
  final Widget child;

  /// An action aligned with the heading — "View all", a small button.
  final Widget? trailing;

  /// Overridable so a panel wrapping a full-bleed table can drop its own
  /// horizontal padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: Radii.card,
        border: Border.all(color: context.semantic.hairline),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Flexible so a wordy trailing label gives way rather than
                // pushing the heading row past the panel's edge.
                if (trailing != null) Flexible(child: trailing!),
              ],
            ),
            const SizedBox(height: Insets.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// A read-only label/value pair.
///
/// Carries [LabeledFormField]'s label treatment so a detail screen's fields sit
/// visually in the same family as the form that edits them — the difference
/// between the two is the control, not the typography.
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.maxLines = 3,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );

    if (icon == null) return text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: Insets.md - 2),
        Expanded(child: text),
      ],
    );
  }
}

/// Lays [LabeledValue]s out in as many columns as the width allows, stacking
/// to one on a phone. The shape every "details" block in the app uses.
class LabeledValueGrid extends StatelessWidget {
  const LabeledValueGrid({
    super.key,
    required this.children,
    this.minColumnWidth = 200,
    this.maxColumns = 3,
  });

  final List<Widget> children;

  /// Narrower than this and a value ellipsises to uselessness, so the grid
  /// drops a column instead.
  final double minColumnWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.lg;
        final fits = (constraints.maxWidth / minColumnWidth).floor();
        // Never more columns than there are children, so two values do not
        // stretch across a three-column grid with a hole in it.
        final ceiling = math.max(1, math.min(maxColumns, children.length));
        final columns = fits.clamp(1, ceiling);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: Insets.lg,
          children: [
            for (final child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
