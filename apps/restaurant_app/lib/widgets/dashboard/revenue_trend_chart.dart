import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_chart_data.dart';
import '../../theme/app_theme.dart';
import '../../theme/dashboard_colors.dart';
import '../../utils/formatters.dart';

/// A curved revenue line with a gradient area beneath it.
///
/// Presentational: it is handed a series and draws it. Everything about where
/// the numbers came from stays in the provider, which is what lets the same
/// chart render a week, a month, or a single store.
class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({
    super.key,
    required this.points,
    this.height,
  });

  final List<RevenuePoint> points;

  /// Defaults to the dashboard's standard chart height for the current width.
  final double? height;

  /// Below this the Y axis labels cost more room than they return, so the
  /// gridlines carry the scale on their own.
  static const double _yAxisMin = 300;

  /// Width per X label before they start colliding. Drives how many days get
  /// a label on a narrow phone.
  static const double _perXLabel = 46;

  static final _weekday = DateFormat('E');

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final family = palette.revenue;

    if (points.isEmpty) {
      return SizedBox(
        height: height ?? DashboardStyle.chartHeightDesktop,
        child: Center(
          child: Text(
            'No sales in this period',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showYAxis = constraints.maxWidth >= _yAxisMin;

        // One label per day where they fit; otherwise every other, every
        // third, and so on — never so many that they overlap.
        final labelStride = math.max(
          1,
          (points.length / (constraints.maxWidth / _perXLabel)).ceil(),
        );

        final maxY = _niceCeiling(
          points.map((p) => p.amount).reduce(math.max),
        );

        return SizedBox(
          height: height ?? DashboardStyle.chartHeightDesktop,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              // Unclipped so the marker on the latest day is not sliced in
              // half by the right edge of the plot area. The card's padding
              // gives the few pixels of overhang somewhere to go.
              clipData: const FlClipData.none(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: palette.gridLine,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showYAxis,
                    reservedSize: 46,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => _AxisLabel(
                      text: _axisMoney(value),
                      align: TextAlign.right,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      // Always label the most recent day, whatever the stride
                      // works out to — "today" is the one a reader looks for.
                      final isLast = index == points.length - 1;
                      if (!isLast && index % labelStride != 0) {
                        return const SizedBox.shrink();
                      }
                      return _AxisLabel(
                        text: _weekday.format(points[index].day),
                        emphasised: isLast,
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        Fmt.money(spot.y),
                        TextStyle(
                          color: context.colors.onInverseSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '\n${Fmt.dayMonth(points[spot.x.round()].day)}',
                            style: TextStyle(
                              color: context.colors.onInverseSurface
                                  .withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].amount),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.3,
                  // Without this a curve through a low point can dip below
                  // zero and paint outside the plot area.
                  preventCurveOverShooting: true,
                  color: family.accent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: FlDotData(
                    show: true,
                    // Only the latest day carries a dot; a dot on every point
                    // turns a seven-day line into a row of beads.
                    checkToShowDot: (spot, _) =>
                        spot.x == (points.length - 1).toDouble(),
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4.5,
                          color: family.accent,
                          strokeWidth: 2.5,
                          strokeColor: context.colors.surfaceContainerLowest,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        family.accent.withValues(alpha: 0.28),
                        family.accent.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Axis money: no cents, thousands as "k".
  ///
  /// [Fmt.moneyCompact] keeps cents below $10k, which renders "$5,500.00" and
  /// then clips inside a 46px gutter — an axis wants the magnitude, not the
  /// exact figure.
  static String _axisMoney(double value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      return '\$${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
    }
    return '\$${value.round()}';
  }

  /// Rounds the top of the scale up to a number a person would choose, so the
  /// gridlines land on readable values instead of $1,847.32.
  ///
  /// The ladder is deliberately fine-grained: jumping straight from 2.5 to 5
  /// puts a peak of 3,480 on a 5,500 scale and leaves the line hugging the
  /// bottom third of the card.
  static double _niceCeiling(double raw) {
    if (raw <= 0) return 100;

    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    // A touch of headroom so the peak never sits exactly on the top gridline.
    final normalised = (raw / magnitude) * 1.02;

    const ladder = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0,
        8.0, 10.0];
    for (final step in ladder) {
      if (normalised <= step) return step * magnitude;
    }
    return 10 * magnitude;
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({
    required this.text,
    this.align = TextAlign.center,
    this.emphasised = false,
  });

  final String text;
  final TextAlign align;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: align,
        style: context.text.labelSmall?.copyWith(
          color: emphasised ? colors.onSurface : colors.onSurfaceVariant,
          fontWeight: emphasised ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
