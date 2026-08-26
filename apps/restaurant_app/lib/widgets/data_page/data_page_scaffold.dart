import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../nav_shell_scope.dart';

/// The shared skeleton for every data page: header, three summary cards,
/// a toolbar, and a table body.
///
/// Everything page-specific arrives as a slot. A new data page (Customers,
/// Staff, …) is a screen that fills in these arguments — it writes no layout
/// of its own.
class DataPageScaffold extends StatelessWidget {
  const DataPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.toolbar,
    required this.table,
    this.actions = const [],
    this.primaryAction,
  });

  final String title;
  final String subtitle;

  /// Export buttons and the like, shown at the top right.
  final List<Widget> actions;

  /// The page's emphasised action — "Add item", a date-range selector — shown
  /// after [actions].
  final Widget? primaryAction;

  /// Exactly three cards: three across on tablet and desktop, stacked on
  /// mobile. More or fewer still lay out, but three is the designed case.
  final List<Widget> metrics;

  final Widget toolbar;
  final Widget table;

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;
    final pad = Insets.page(form);
    final isMobile = form.isMobile;
    final spacing = isMobile ? Insets.md : Insets.xl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            isMobile ? Insets.sm : Insets.md,
            pad,
            isMobile ? Insets.sm : pad,
          ),
          children: [
            _PageHeader(
              title: title,
              subtitle: subtitle,
              actions: actions,
              primaryAction: primaryAction,
            ),
            SizedBox(height: isMobile ? spacing : Insets.xl),
            _MetricsRow(metrics: metrics),
            SizedBox(height: spacing),
            toolbar,
            SizedBox(height: isMobile ? Insets.md : Insets.lg),
            table,
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.primaryAction,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final heading = Row(
      children: [
        const NavMenuButton(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final buttons = <Widget>[...actions, ?primaryAction];

    if (buttons.isEmpty) return heading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = context.isMobile;
        // Wide enough for the title and every button on one line; otherwise
        // the buttons wrap under the heading rather than crushing it.
        final inline = constraints.maxWidth >= 760;

        final actionBar = Wrap(
          spacing: isMobile ? 4.0 : Insets.sm,
          runSpacing: isMobile ? 4.0 : Insets.sm,
          alignment: inline ? WrapAlignment.end : WrapAlignment.start,
          children: buttons,
        );

        if (inline) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heading),
              SizedBox(width: isMobile ? Insets.md : Insets.lg),
              Flexible(child: actionBar),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            SizedBox(height: isMobile ? Insets.sm : Insets.lg),
            actionBar,
          ],
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<Widget> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = Insets.md;
        // One column on mobile, three across everywhere else.
        final columns = constraints.maxWidth < Breakpoints.tablet
            ? 1
            : metrics.length;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(width: width, child: metric),
          ],
        );
      },
    );
  }
}
