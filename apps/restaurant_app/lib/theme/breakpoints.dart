import 'package:flutter/widgets.dart';

/// Layout classes used throughout the app.
///
/// Everything responsive keys off these instead of raw numbers so the
/// breakpoints can be tuned in exactly one place.
enum FormFactor {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == FormFactor.mobile;
  bool get isTablet => this == FormFactor.tablet;
  bool get isDesktop => this == FormFactor.desktop;

  /// True where there is room for a persistent side panel next to content.
  bool get hasSidePanel => this != FormFactor.mobile;
}

abstract final class Breakpoints {
  /// Below this width we lay out for a phone.
  static const double tablet = 600;

  /// At or above this width we lay out for desktop / web.
  static const double desktop = 1024;

  /// Above this the navigation rail can afford to show labels inline.
  static const double extendedRail = 1280;

  /// Content never stretches wider than this on very large displays.
  static const double maxContentWidth = 1600;

  static FormFactor of(double width) {
    if (width >= desktop) return FormFactor.desktop;
    if (width >= tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }
}

extension ResponsiveContext on BuildContext {
  /// Form factor derived from the full window width.
  ///
  /// Prefer a [LayoutBuilder] with [Breakpoints.of] when sizing something
  /// inside a constrained region — this getter describes the window, not the
  /// box the widget happens to sit in.
  FormFactor get formFactor => Breakpoints.of(MediaQuery.sizeOf(this).width);

  bool get isMobile => formFactor.isMobile;
  bool get isDesktop => formFactor.isDesktop;
}

/// Spacing scale. Multiples of 4, named so layout code reads as intent.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen padding that grows with the viewport.
  static double page(FormFactor f) => switch (f) {
    FormFactor.mobile => lg,
    FormFactor.tablet => xl,
    FormFactor.desktop => xxl,
  };
}

/// Sizing rules for the POS item grid and the order panel beside it.
abstract final class Layout {
  /// Width of the persistent order panel. Absent on mobile, where the cart
  /// becomes a bottom bar and sheet instead.
  static double orderPanel(FormFactor f) => f.isDesktop ? 320 : 210;

  /// How many columns of menu cards fit in [width].
  ///
  /// The count is computed from the width the grid actually received — after
  /// the rail and the order panel have taken theirs — so it stays right at
  /// window sizes nobody thought to test. The form factor supplies the density
  /// rule: how wide a card wants to be, and the range that stays usable.
  static int columnsFor(double width, FormFactor form) {
    final (target, min, max) = switch (form) {
      // Three columns on mobile for better use of space with compact cards.
      FormFactor.mobile => (130.0, 3, 3),
      FormFactor.tablet => (160.0, 2, 4),
      // Desktop is pinned to a four-up grid at every width. A counter terminal
      // is a fixed installation, and muscle memory for where an item sits is
      // worth more to a cashier than an extra column on a wider monitor — the
      // cards grow into the space instead.
      FormFactor.desktop => (190.0, 4, 4),
    };

    if (width <= 0 || !width.isFinite) return min;
    return (width / target).floor().clamp(min, max);
  }
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius panel = BorderRadius.all(Radius.circular(lg));
}
