import 'package:flutter/material.dart';

import '../../models/business_role.dart';
import '../../theme/app_theme.dart';
import '../data_page/status_badge.dart';

/// A role rendered as a coloured pill.
///
/// Roles are not statuses — "Cashier" is not better or worse than "Manager", so
/// the semantic tones do not apply. Instead each role gets a stable colour from
/// a fixed palette, fed to [StatusBadge] through its colour override so the
/// pill shape, spacing and icon pairing stay identical to every other badge in
/// the app.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.dense = false});

  final BusinessRole? role;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final role = this.role;

    // A member whose role was deleted still has to render as something.
    if (role == null) {
      return StatusBadge(
        label: 'No role',
        tone: StatusTone.neutral,
        icon: Icons.help_outline_rounded,
        dense: dense,
      );
    }

    return StatusBadge(
      label: role.name,
      tone: StatusTone.neutral,
      color: roleColor(context, role),
      icon: roleIcon(role),
      dense: dense,
    );
  }

  /// The palette custom roles draw from. Chosen to stay distinguishable from
  /// each other *and* from the success/warning/danger tones, so a role badge is
  /// never mistaken for a status one.
  static const _palette = <Color>[
    Color(0xFF6C4FD8), // violet
    Color(0xFF0F7B9C), // cyan
    Color(0xFFB25E00), // amber-brown
    Color(0xFF9B2C6F), // magenta
    Color(0xFF3F6212), // olive
    Color(0xFF1D4ED8), // indigo
  ];

  /// Dark-mode equivalents. The light palette's saturated mid-tones fail
  /// contrast against a near-black surface, so each has a lifted counterpart
  /// rather than being programmatically brightened.
  static const _paletteDark = <Color>[
    Color(0xFFB9A6FF),
    Color(0xFF6FD3EE),
    Color(0xFFF3B268),
    Color(0xFFF09BCE),
    Color(0xFFAFD26B),
    Color(0xFF9DB8FF),
  ];

  /// System roles get fixed slots so Owner is always the same colour across
  /// every install; custom roles hash into the remainder of the palette.
  static Color roleColor(BuildContext context, BusinessRole role) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark ? _paletteDark : _palette;

    final index = switch (role.id) {
      'role-owner' => 0,
      'role-manager' => 1,
      'role-cashier' => 2,
      _ => 3 + (role.id.hashCode & 0x7fffffff) % (palette.length - 3),
    };

    return palette[index];
  }

  static IconData roleIcon(BusinessRole role) => switch (role.id) {
    'role-owner' => Icons.workspace_premium_outlined,
    'role-manager' => Icons.badge_outlined,
    'role-cashier' => Icons.point_of_sale_outlined,
    _ => role.isProtected
        ? Icons.badge_outlined
        : Icons.person_outline_rounded,
  };
}

/// The circular initials avatar used wherever a staff member is listed.
///
/// Tinted by the member's role, so the table reads as grouped by role even
/// before the badges are scanned.
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({
    super.key,
    required this.initials,
    this.role,
    this.size = 36,
  });

  final String initials;
  final BusinessRole? role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final role = this.role;
    final accent = role == null
        ? context.colors.onSurfaceVariant
        : RoleBadge.roleColor(context, role);

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        initials,
        maxLines: 1,
        style: context.text.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
          // Scales with the circle so the same widget serves a 36px table cell
          // and a 56px detail header.
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
