import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import 'shake.dart';

/// The masked progress dots above a PIN keypad.
///
/// Filled dots rather than digits, and a shake rather than a red banner: a PIN
/// pad is used in front of customers, so it says how far you have got and
/// nothing about what you typed.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
    this.success = false,
    this.shakeToken = 0,
  });

  final int length;
  final int filled;

  final bool error;

  /// Flashes the dots in the success colour before the screen moves on.
  final bool success;

  /// Bumped by the parent on every rejected entry. A counter rather than a
  /// bool, so three wrong PINs in a row shake three times instead of once.
  final int shakeToken;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;

    final tone = success
        ? semantic.success
        : error
        ? semantic.danger
        : colors.primary;

    return Shake(
      token: shakeToken,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.sm - 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < filled ? tone : Colors.transparent,
                  border: Border.all(
                    color: i < filled
                        ? tone
                        : (error
                              ? semantic.danger.withValues(alpha: 0.6)
                              : colors.outlineVariant),
                    width: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The on-screen number pad a PIN is entered on.
///
/// Deliberately not the system keyboard: a POS terminal is often a fixed
/// tablet where the software keyboard covers half the screen, and a keypad the
/// app draws itself can give every key a target far larger than a keyboard
/// row would.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.trailing,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// False during a lockout or while a PIN is being checked.
  final bool enabled;

  /// Optional control in the pad's bottom-left slot, opposite backspace.
  final Widget? trailing;

  /// Comfortably above the 44px floor: PIN entry is done quickly, often
  /// one-handed, and a mis-tap costs an attempt.
  static const double keySize = 56;

  static const double _gap = Insets.md;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keys grow into a wide card but never shrink below the touch floor;
        // three columns plus two gaps is the whole budget.
        final available = (constraints.maxWidth - _gap * 2) / 3;
        final size = available.clamp(keySize, 78.0);

        Widget key(String digit) => _KeypadKey(
          size: size,
          enabled: enabled,
          onTap: () => onDigit(digit),
          child: Text(
            digit,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? context.colors.onSurface
                  : context.colors.onSurface.withValues(alpha: 0.35),
            ),
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ]) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final digit in row) ...[
                    if (digit != row.first) const SizedBox(width: _gap),
                    key(digit),
                  ],
                ],
              ),
              const SizedBox(height: _gap),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: size,
                  width: size,
                  child: trailing == null
                      ? null
                      : Center(child: trailing),
                ),
                const SizedBox(width: _gap),
                key('0'),
                const SizedBox(width: _gap),
                _KeypadKey(
                  size: size,
                  enabled: enabled,
                  onTap: onBackspace,
                  tooltip: 'Delete',
                  filled: false,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: enabled
                        ? context.colors.onSurfaceVariant
                        : context.colors.onSurfaceVariant.withValues(
                            alpha: 0.35,
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.size,
    required this.enabled,
    required this.onTap,
    required this.child,
    this.filled = true,
    this.tooltip,
  });

  final double size;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled
          ? context.colors.surfaceContainerHigh.withValues(
              alpha: enabled ? 1 : 0.4,
            )
          : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: size,
          width: size,
          child: Center(child: child),
        ),
      ),
    );

    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
