import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_text_styles.dart';

/// Modern shimmer / skeleton loader used as the default loading state
/// for lists, tables, and card grids.
///
/// A shimmer pattern (skeleton lines with a gradient sweep) is preferred
/// over a bare spinner for content areas because it communicates
/// *shape* (how many rows/columns are loading) and is perceived as
/// faster by users.  Full-page / boot states that don't have a known
/// layout shape should continue to use the spinner-based
/// [LoadingIndicator] instead.
///
/// Three convenience constructors cover the most common skeletons:
/// - [SkeletonLoader.line] — a single horizontal bar.
/// - [SkeletonLoader.listTile] — leading box + two text lines (matches
///   the shape of a list-row / inventory-item row).
/// - [SkeletonLoader.gridTile] — image box + label + value line
///   (matches the shape of a POS product-card).
///
/// Pass [count] > 1 to render a Column of repeated skeletons with the
/// specified gap between items.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    required this.child,
    this.count = 1,
    this.gap = AppDimensions.spaceSM,
  }) : assert(count > 0, 'count must be >= 1');

  /// A single bar, `width` x `height`.
  factory SkeletonLoader.line({
    Key? key,
    double width = double.infinity,
    double height = 16,
    BorderRadius? radius,
    int count = 1,
    double gap = AppDimensions.spaceSM,
  }) {
    return SkeletonLoader(
      key: key,
      count: count,
      gap: gap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius ?? BorderRadius.circular(AppDimensions.radiusXS),
        ),
      ),
    );
  }

  /// List-tile-shaped skeleton: leading box + title line + sub line.
  factory SkeletonLoader.listTile({
    Key? key,
    double leadingSize = 56,
    int count = 1,
    double gap = AppDimensions.spaceMD,
  }) {
    return SkeletonLoader(
      key: key,
      count: count,
      gap: gap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: leadingSize,
            height: leadingSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXS),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXS),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid-tile-shaped skeleton: large image box + short label line.
  factory SkeletonLoader.gridTile({Key? key}) {
    return SkeletonLoader(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
            ),
          ),
        ],
      ),
    );
  }

  final Widget child;
  final int count;
  final double gap;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = cs.surfaceContainerHighest;
    final highlightColor = cs.surfaceContainerHighest.withValues(alpha: 0.2);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.45, 0.55, 1.0],
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
              ],
              transform: _SlideGradient(_ctrl.value * 2 - 1),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.count == 1
              ? widget.child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.count; i++) ...[
                      if (i > 0) SizedBox(height: widget.gap),
                      widget.child,
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.offset);
  final double offset;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * offset, 0, 0);
  }
}

/// Centred spinner-based loading indicator, retained for full-page /
/// boot states (e.g. [_resolveBootSession]) where a skeleton would be
/// misleading because the eventual layout shape isn't yet known.
///
/// Prefer [SkeletonLoader] for content areas that have a predictable
/// shape (lists, tables, product grids).
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: cs.primary,
            strokeWidth: 2.5,
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spaceMD),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
