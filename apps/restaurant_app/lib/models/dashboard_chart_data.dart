import 'package:flutter/foundation.dart';

/// One day on the revenue trend.
@immutable
class RevenuePoint {
  const RevenuePoint({required this.day, required this.amount});

  /// Midnight of the day this covers.
  final DateTime day;

  /// Takings for that day, net of refunds and voids.
  final double amount;
}

/// One slice of the sales-by-category breakdown.
///
/// Carries an absolute [value] rather than a pre-computed percentage, so the
/// chart and its legend derive their percentages from the same total and can
/// never disagree about rounding.
@immutable
class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.value,
    this.colorIndex = 0,
  });

  final String label;
  final double value;

  /// Which entry of the dashboard palette this slice paints with.
  ///
  /// Assigned from the category catalogue rather than from the slice's
  /// position in a sorted list, so a category keeps its colour when the
  /// ordering changes — and matches the rank badge for the same category in
  /// the list beside the chart.
  final int colorIndex;
}

/// Helpers shared by the donut and its legend.
extension CategorySliceList on List<CategorySlice> {
  double get total => fold<double>(0, (sum, slice) => sum + slice.value);

  /// Share of the whole, 0–1. Zero when there is nothing to divide by, which
  /// is what keeps an empty day from producing NaN sweep angles.
  double shareOf(CategorySlice slice) {
    final whole = total;
    return whole <= 0 ? 0 : slice.value / whole;
  }
}
