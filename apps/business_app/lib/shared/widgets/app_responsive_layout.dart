import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Responsive layout helper driven by [AppDimensions] breakpoints.
///
/// Exposes [isMobile], [isTablet], [isDesktop] and the adaptive
/// [horizontalPadding] / [contentMaxWidth] values so every screen
/// maintains consistent visual rhythm across form-factors.
///
/// Usage:
/// ```dart
/// AppResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),
///   desktop: DesktopView(),  // falls back to tablet if omitted
/// )
/// ```
class AppResponsiveLayout extends StatelessWidget {
  const AppResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget? desktop;

  /// Returns `true` when [width] is below the tablet breakpoint.
  static bool isMobileWidth(double width) =>
      width < AppDimensions.breakpointTablet;

  /// Returns `true` when [width] is at or above the tablet breakpoint
  /// but below the desktop breakpoint.
  static bool isTabletWidth(double width) =>
      width >= AppDimensions.breakpointTablet &&
      width < AppDimensions.breakpointDesktop;

  /// Returns `true` when [width] is at or above the desktop breakpoint.
  static bool isDesktopWidth(double width) =>
      width >= AppDimensions.breakpointDesktop;

  /// Horizontal content padding scaled to the current breakpoint.
  static double horizontalPaddingFor(double width) {
    if (isDesktopWidth(width)) return AppDimensions.spaceXXXL;
    if (isTabletWidth(width)) return AppDimensions.spaceXL;
    return AppDimensions.spaceMD;
  }

  /// Maximum content width for centred single-column layouts
  /// (auth pages, settings, etc.).
  static double contentMaxWidthFor(double width) {
    if (isDesktopWidth(width)) return 480;
    if (isTabletWidth(width)) return 440;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (isDesktopWidth(w)) return desktop ?? tablet;
        if (isTabletWidth(w)) return tablet;
        return mobile;
      },
    );
  }
}

/// Convenience extension on [BuildContext] for breakpoint queries.
extension ResponsiveContext on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  bool get isMobile => AppResponsiveLayout.isMobileWidth(_width);
  bool get isTablet => AppResponsiveLayout.isTabletWidth(_width);
  bool get isDesktop => AppResponsiveLayout.isDesktopWidth(_width);

  double get horizontalPadding =>
      AppResponsiveLayout.horizontalPaddingFor(_width);

  double get contentMaxWidth =>
      AppResponsiveLayout.contentMaxWidthFor(_width);
}
