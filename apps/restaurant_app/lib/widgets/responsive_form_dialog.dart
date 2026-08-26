import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

/// Presents a modal form the way the current screen size wants it.
///
/// On tablet and desktop that is a centered dialog over a dimmed backdrop; on
/// a phone a centered fixed-width box is the wrong shape entirely, so the same
/// content comes up as a near-full-height modal sheet instead.
///
/// Callers build one [ResponsiveFormDialog] and hand it to this function — the
/// breakpoint is decided here and inside the widget, in agreement, so no call
/// site has to branch on width itself.
Future<T?> showResponsiveFormDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (MediaQuery.sizeOf(context).width < Breakpoints.tablet) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      // The sheet paints nothing: [ResponsiveFormDialog] draws its own surface
      // and rounded top so it can size itself against the keyboard.
      backgroundColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      isDismissible: barrierDismissible,
      enableDrag: barrierDismissible,
      // Deliberately off: the widget subtracts the status bar and the keyboard
      // itself, and a SafeArea out here would strip the padding values it
      // needs to do that.
      useSafeArea: false,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

/// Chrome for a modal form: a title row with a close button, a scrolling body,
/// and a footer of actions pinned below it.
///
/// The body is the only part that scrolls, so the primary action never walks
/// off the bottom of a long form — and on a phone it stays above the system
/// keyboard rather than behind it.
class ResponsiveFormDialog extends StatelessWidget {
  const ResponsiveFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.width,
    this.onClose,
  });

  final String title;

  /// The form body. Sized by its own content; scrolls when it outgrows the
  /// space available.
  final Widget child;

  /// Footer buttons, secondary first. Laid out right-aligned on a wide screen
  /// and stretched edge to edge on a phone, where a thumb wants the width.
  final List<Widget> actions;

  /// Dialog width on tablet and desktop. Confirmations want the default; a
  /// two-column form wants considerably more.
  final double? width;

  /// Runs instead of a plain `pop()` when the header's X is pressed — for a
  /// form that needs to confirm before discarding.
  final VoidCallback? onClose;

  /// Comfortable for a single column of fields. Forms that lay out wider
  /// content pass their own.
  static const double defaultWidth = 460;

  /// A dialog never grows past this share of the window, so a short window (or
  /// a large text scale) scrolls the body instead of clipping it.
  static const double _maxHeightFactor = 0.85;

  /// The sheet leaves a strip of the page visible behind it, which is what
  /// tells the user this is a layer over the list rather than a new screen.
  static const double _sheetHeightFactor = 0.95;

  /// Marks the box that is actually the dialog — the one whose width and
  /// height the layout rules are about. Both presentations carry it, so a test
  /// can measure the modal without knowing which one it got.
  static const Key surfaceKey = Key('responsiveFormDialog.surface');

  @override
  Widget build(BuildContext context) {
    return MediaQuery.sizeOf(context).width < Breakpoints.tablet
        ? _buildSheet(context)
        : _buildDialog(context);
  }

  // ---------------------------------------------------------------------
  // Tablet / desktop
  // ---------------------------------------------------------------------

  Widget _buildDialog(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(Insets.xl),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        key: surfaceKey,
        constraints: BoxConstraints(
          // Clamped to what the window can actually give: a 640px dialog on a
          // 600px tablet has to become a 552px one rather than overflow.
          maxWidth: math.min(
            width ?? defaultWidth,
            math.max(280.0, size.width - Insets.xl * 2),
          ),
          maxHeight: size.height * _maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(title: title, onClose: onClose),
            const Divider(height: 1),
            // Flexible, not Expanded: the dialog hugs a short form and only
            // starts scrolling once the body outgrows the height cap.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Insets.xl),
                child: child,
              ),
            ),
            const Divider(height: 1),
            _Footer(actions: actions, stretch: false),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mobile
  // ---------------------------------------------------------------------

  Widget _buildSheet(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    // Measured from below the status bar, then shortened by the keyboard and
    // pushed up by the same amount: the sheet keeps its proportions and the
    // footer stays visible while a field is being typed into.
    final available = media.size.height - media.padding.top;
    final height = math.max(280.0, available * _sheetHeightFactor - keyboard);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        key: surfaceKey,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Radii.lg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        // Bottom only — the top is already clear of the status bar, and
        // MediaQuery zeroes the bottom inset while the keyboard is up.
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _Header(title: title, onClose: onClose),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: child,
                ),
              ),
              const Divider(height: 1),
              _Footer(actions: actions, stretch: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.md,
        Insets.md,
        Insets.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleLarge,
            ),
          ),
          const SizedBox(width: Insets.sm),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.actions, required this.stretch});

  final List<Widget> actions;

  /// Phones give each action an equal share of the width; wider screens right
  /// -align them at their natural size.
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    if (stretch) {
      final spaced = <Widget>[];
      for (var i = 0; i < actions.length; i++) {
        if (i > 0) spaced.add(const SizedBox(width: Insets.md));
        spaced.add(Expanded(child: actions[i]));
      }
      return Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Row(children: spaced),
      );
    }

    // A Wrap rather than a Row: two buttons with long labels ("Cancel" +
    // "Confirm adjustment") can outgrow a 480px dialog once the text scale is
    // turned up, and a Row would paint them past its edge. Wrapping puts the
    // primary action on its own line instead, still right-aligned.
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: Insets.md,
        runSpacing: Insets.sm,
        children: actions,
      ),
    );
  }
}
