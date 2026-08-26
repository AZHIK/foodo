import 'package:flutter/material.dart';

/// The accent colours a business can brand itself with.
///
/// Drawn from the hues already in use across the app — the seed teal, the
/// dashboard's four KPI accents and the two extra donut colours — rather than a
/// fresh palette, so a venue that picks "Coral" gets a colour the rest of the
/// UI already knows how to sit next to.
abstract final class BrandPalette {
  static const swatches = <BrandSwatch>[
    BrandSwatch('Emerald', Color(0xFF0B6B57)),
    BrandSwatch('Ocean', Color(0xFF1B4FD8)),
    BrandSwatch('Coral', Color(0xFFC2410C)),
    BrandSwatch('Violet', Color(0xFF6D28D9)),
    BrandSwatch('Amber', Color(0xFFB4790A)),
    BrandSwatch('Rose', Color(0xFFB0246A)),
    BrandSwatch('Slate', Color(0xFF3F4B57)),
    BrandSwatch('Espresso', Color(0xFF5B3A21)),
  ];

  /// The swatch matching [color], or null when the business has been given a
  /// custom colour the presets do not cover.
  static BrandSwatch? match(Color color) {
    for (final swatch in swatches) {
      if (swatch.color.toARGB32() == color.toARGB32()) return swatch;
    }
    return null;
  }

  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

@immutable
class BrandSwatch {
  const BrandSwatch(this.name, this.color);

  final String name;
  final Color color;
}
