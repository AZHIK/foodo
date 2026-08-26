import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

/// The app's logo mark: a gradient tile carrying the business's own logo where
/// one has been uploaded, and the house restaurant glyph where it has not.
///
/// Lifted out of the nav rail so the auth screens can show the *same* mark
/// rather than a lookalike — the splash, the login card and the sidebar a
/// second later have to be recognisably one product.
class BrandMark extends ConsumerWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final logo = ref.watch(
      businessProfileProvider.select((profile) => profile.logoBytes),
    );

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: logo == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  Color.lerp(colors.primary, colors.tertiary, .55)!,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logo == null
          ? Icon(
              Icons.restaurant_rounded,
              // Tracks the tile, so one widget serves a 40px rail header and a
              // 72px splash mark without a second set of numbers.
              size: size * 0.55,
              color: colors.onPrimary,
            )
          : Image.memory(logo, fit: BoxFit.cover, width: size, height: size),
    );
  }
}

/// The brand mark with the business name beside it, as the nav rail and drawer
/// show it.
class BrandLockup extends ConsumerWidget {
  const BrandLockup({super.key, this.subtitle = 'Front of house'});

  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const BrandMark(),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ref.watch(storeNameProvider),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
