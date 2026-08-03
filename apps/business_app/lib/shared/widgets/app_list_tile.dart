import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Styled list tile following the app design system.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isDestructive = false,
    this.enabled = true,
    this.selected = false,
    this.contentPadding,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDestructive;
  final bool enabled;
  final bool selected;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = isDestructive
        ? colorScheme.error
        : (enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.38));

    return ListTile(
      leading: leading,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      selected: selected,
      enabled: enabled,
      dense: dense,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceXS,
          ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
    );
  }
}

/// A group of [AppListTile]s in a rounded card, with auto-dividers.
class AppListTileGroup extends StatelessWidget {
  const AppListTileGroup({
    super.key,
    required this.tiles,
    this.header,
    this.margin,
  });

  final List<Widget> tiles;
  final String? header;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceSM,
              AppDimensions.spaceSM,
              AppDimensions.spaceSM,
              AppDimensions.spaceXS,
            ),
            child: Text(
              header!.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          margin: margin ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1)
                  Divider(
                    height: 1,
                    indent: AppDimensions.spaceMD,
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
