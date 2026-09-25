import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_strings.dart';
import '../../printing/thermal_receipt.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';

/// Paper look-alike of an 80mm thermal receipt.
///
/// Renders the same [ThermalLine]s the printer encoder consumes, so what the
/// owner approves here is what the paper carries: `text` rows in a
/// fixed-width face, `rule` as a dashed separator, and the `qr` marker as a
/// real scannable code.
class ThermalReceiptPreview extends StatelessWidget {
  const ThermalReceiptPreview({super.key, required this.lines});

  final List<ThermalLine> lines;

  /// ~80mm at 96dpi, the width a preview should never exceed.
  static const double paperWidth = 320;

  static const _face = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.45,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: paperWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: context.semantic.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in lines) _Row(line: line),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.line});

  final ThermalLine line;

  @override
  Widget build(BuildContext context) {
    switch (line.kind) {
      case ThermalLineKind.blank:
        return const SizedBox(height: 8);
      case ThermalLineKind.rule:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: _Dashes(),
        );
      case ThermalLineKind.qr:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: line.text, size: 160, version: QrVersions.auto),
              const SizedBox(height: 4),
              Text(
                AppStrings.receiptScanHint,
                style: ThermalReceiptPreview._face.copyWith(fontSize: 11),
              ),
            ],
          ),
        );
      case ThermalLineKind.text:
        return Text(
          line.text,
          textAlign: switch (line.align) {
            ThermalAlign.left => TextAlign.left,
            ThermalAlign.center => TextAlign.center,
            ThermalAlign.right => TextAlign.right,
          },
          style: ThermalReceiptPreview._face.copyWith(
            fontWeight: line.bold ? FontWeight.w700 : FontWeight.w400,
            // Double-size rows (a coupon's order number): the paper's most
            // visible line, matching the printer's double width/height mode.
            fontSize: line.big ? 24 : null,
            height: line.big ? 1.2 : null,
          ),
        );
    }
  }
}

/// Dashed separator that stretches edge to edge, like a thermal rule.
class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 5.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              const SizedBox(
                width: dash,
                child: Divider(height: 1, thickness: 1, color: Colors.black54),
              ),
          ],
        );
      },
    );
  }
}
