import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import 'app_card.dart';

/// Generic label + value card for simple read-only display needs.
///
/// Supports two layouts selected via [variant]:
/// - [InfoCardVariant.row] — label and value side-by-side in a single
///   row.  Good for dense summary tables (e.g. sale totals).
/// - [InfoCardVariant.stack] — label above value.  Good when the value
///   is long or needs more visual weight.
///
/// An optional trailing slot lets you add an edit button, status chip,
/// or other affordance without wrapping in another Row.
///
/// Usage:
/// ```dart
/// InfoCard(
///   label: 'Customer',
///   value: 'Mwanza Restaurant',
///   trailing: Icon(Icons.chevron_right),
///   onTap: _openCustomer,
/// )
/// ```
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    this.variant = InfoCardVariant.row,
    this.description,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String label;
  final String value;
  final InfoCardVariant variant;

  /// Optional secondary block of text shown below the value.
  final String? description;

  /// Widget placed after the value block — e.g. a chevron or status
  /// chip.
  final Widget? trailing;

  /// Widget placed before the label/value block.
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelText = Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: cs.onSurface.withValues(alpha: 0.55),
        letterSpacing: 0.3,
      ),
    );
    final valueText = Text(
      value,
      style: AppTextStyles.titleMedium.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
    final descText = description != null
        ? Text(
            description!,
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          )
        : null;

    return AppCard.flat(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: switch (variant) {
        InfoCardVariant.row => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppDimensions.spaceMD),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelText,
                    const SizedBox(height: AppDimensions.spaceXXS),
                    valueText,
                    if (descText != null) ...[
                      const SizedBox(height: AppDimensions.spaceXS),
                      descText,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppDimensions.spaceSM),
                trailing!,
              ],
            ],
          ),
        InfoCardVariant.stack => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: AppDimensions.spaceSM),
              ],
              labelText,
              const SizedBox(height: AppDimensions.spaceXXS),
              valueText,
              if (descText != null) ...[
                const SizedBox(height: AppDimensions.spaceXS),
                descText,
              ],
              if (trailing != null) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Align(
                  alignment: Alignment.centerRight,
                  child: trailing,
                ),
              ],
            ],
          ),
      },
    );
  }
}

enum InfoCardVariant { row, stack }
