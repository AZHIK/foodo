/// The palette role badges draw from, as a [ThemeExtension].
///
/// Chosen to stay distinguishable from each other *and* from the
/// success/warning/danger tones, so a role badge is never mistaken for a
/// status one. Dark-mode equivalents are lifted counterparts rather than
/// programmatically brightened — the light palette's saturated mid-tones
/// fail contrast against a near-black surface.
///
/// System roles get fixed slots so Owner is always the same colour across
/// every install; custom roles hash into the remainder of the palette.
library;

import 'package:flutter/material.dart';

@immutable
class RoleBadgeColors extends ThemeExtension<RoleBadgeColors> {
  const RoleBadgeColors({required this.palette});

  final List<Color> palette;

  static const light = RoleBadgeColors(
    palette: [
      Color(0xFF6C4FD8), // violet
      Color(0xFF0F7B9C), // cyan
      Color(0xFFB25E00), // amber-brown
      Color(0xFF9B2C6F), // magenta
      Color(0xFF3F6212), // olive
      Color(0xFF1D4ED8), // indigo
    ],
  );

  static const dark = RoleBadgeColors(
    palette: [
      Color(0xFFB9A6FF),
      Color(0xFF6FD3EE),
      Color(0xFFF3B268),
      Color(0xFFF09BCE),
      Color(0xFFAFD26B),
      Color(0xFF9DB8FF),
    ],
  );

  @override
  RoleBadgeColors copyWith({List<Color>? palette}) =>
      RoleBadgeColors(palette: palette ?? this.palette);

  @override
  RoleBadgeColors lerp(ThemeExtension<RoleBadgeColors>? other, double t) {
    if (other is! RoleBadgeColors || other.palette.length != palette.length) {
      return this;
    }
    return RoleBadgeColors(
      palette: [
        for (var i = 0; i < palette.length; i++)
          Color.lerp(palette[i], other.palette[i], t)!,
      ],
    );
  }
}

extension RoleBadgeTheme on ThemeData {
  RoleBadgeColors get roleBadges => extension<RoleBadgeColors>()!;
}

extension RoleBadgeContext on BuildContext {
  RoleBadgeColors get roleBadges => Theme.of(this).roleBadges;
}
