import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/dashboard_chart_data.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../theme/dashboard_colors.dart';
import '../../utils/formatters.dart';

/// Sales split by category, as a donut with a total in the hole and a custom
/// legend beneath it.
///
/// The legend is built here rather than taken from fl_chart so it carries the
/// app's own typography and can show a name, a swatch and a percentage on one
/// line — three things the built-in legend has no room for.
class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    this.height,
  });

  final List<CategorySlice> slices;

  /// Height of the donut itself. The legend is laid out below and adds its own.
  final double? height;

  /// Fraction of the ring's radius left empty in the middle.
  static const double _holeRatio = 0.62;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  /// Index of the slice under the pointer, or null. Drives the slight pop-out
  /// and swaps the centre readout to that category.
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final slices = widget.slices;
    final total = slices.total;

    if (slices.isEmpty || total <= 0) {
      return SizedBox(
        height: widget.height ?? DashboardStyle.chartHeightDesktop,
        child: Center(
          child: Text(
            'No sales to break down yet',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Guarded here as well as in the touch callback: the slice list can shrink
    // under a held selection when the dashboard's range changes.
    final touched =
        _touched != null && _touched! >= 0 && _touched! < slices.length
            ? _touched
            : null;

    final ringHeight = widget.height ??
        (context.isMobile
            ? DashboardStyle.chartHeightMobile
            : DashboardStyle.chartHeightDesktop);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: ringHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The ring is sized from the smaller dimension so it stays
              // circular and inside its box at every width.
              final diameter = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final radius = diameter / 2;
              final hole = radius * CategoryDonutChart._holeRatio;
              final thickness = radius - hole;

              return Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        for (var i = 0; i < slices.length; i++)
                          _section(
                            context: context,
                            slice: slices[i],
                            share: slices.shareOf(slices[i]),
                            // Keyed to the slice's own colour index, not its
                            // position here, so re-sorting the chart cannot
                            // recolour a category.
                            colour: palette
                                .category(slices[i].colorIndex)
                                .accent,
                            // The touched slice grows outward slightly, which
                            // reads as selection without moving the ring.
                            radius: touched == i
                                ? thickness + 6
                                : thickness,
                            showLabel: thickness >= 26,
                          ),
                      ],
                      centerSpaceRadius: hole,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          // fl_chart reports a section with index -1 for
                          // touches that land in the hole or outside the ring,
                          // so an index has to be range-checked, not just
                          // null-checked.
                          final index =
                              response?.touchedSection?.touchedSectionIndex ??
                                  -1;
                          final next = !event.isInterestedForInteractions ||
                                  index < 0 ||
                                  index >= slices.length
                              ? null
                              : index;
                          if (next != _touched) {
                            setState(() => _touched = next);
                          }
                        },
                      ),
                    ),
                  ),
                  _CentreReadout(
                    // Falls back to the total when nothing is touched, so the
                    // hole always says something useful.
                    label: touched == null
                        ? 'Total'
                        : slices[touched].label,
                    value: touched == null
                        ? Fmt.moneyCompact(total)
                        : Fmt.percent(slices.shareOf(slices[touched])),
                    maxWidth: hole * 1.7,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: Insets.lg),
        _Legend(
          slices: slices,
          palette: palette,
          highlighted: touched,
        ),
      ],
    );
  }

  PieChartSectionData _section({
    required BuildContext context,
    required CategorySlice slice,
    required double share,
    required Color colour,
    required double radius,
    required bool showLabel,
  }) {
    // A percentage printed inside a thin ring is unreadable, and one printed
    // on a 3% sliver overflows it — both get dropped and the legend covers it.
    final label = showLabel && share >= 0.08
        ? '${(share * 100).round()}%'
        : '';

    return PieChartSectionData(
      value: slice.value,
      color: colour,
      radius: radius,
      title: label,
      titleStyle: TextStyle(
        // Picked against the slice, not the theme: dark mode's palette is
        // pastel, and white-on-mint is the one pairing on this screen that
        // fails contrast outright.
        color: ThemeData.estimateBrightnessForColor(colour) == Brightness.light
            ? Colors.black.withValues(alpha: 0.82)
            : Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        height: 1,
      ),
      titlePositionPercentageOffset: 0.5,
    );
  }
}

class _CentreReadout extends StatelessWidget {
  const _CentreReadout({
    required this.label,
    required this.value,
    required this.maxWidth,
  });

  final String label;
  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The custom legend: swatch, name, percentage — one row per category, two
/// columns where there is room.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.slices,
    required this.palette,
    required this.highlighted,
  });

  final List<CategorySlice> slices;
  final DashboardPalette palette;
  final int? highlighted;

  /// Below this a two-column legend squeezes names to an ellipsis, so it goes
  /// single column instead.
  static const double _twoColumnMin = 320;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= _twoColumnMin ? 2 : 1;
        const spacing = Insets.md;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: Insets.sm,
          children: [
            for (var i = 0; i < slices.length; i++)
              SizedBox(
                width: width,
                child: _LegendRow(
                  label: slices[i].label,
                  share: slices.shareOf(slices[i]),
                  colour: palette.category(slices[i].colorIndex).accent,
                  dimmed: highlighted != null && highlighted != i,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.share,
    required this.colour,
    required this.dimmed,
  });

  final String label;
  final double share;
  final Color colour;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dimmed ? 0.4 : 1,
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: Insets.xs),
          Text(
            '${(share * 100).round()}%',
            maxLines: 1,
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
