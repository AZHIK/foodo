import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

/// A checkmark that fades in on save and out a moment later.
///
/// Used by every screen that saves as you go — App Preferences and Account
/// Settings today. One implementation, so two live-save screens cannot
/// confirm differently.
class SavedTick extends StatefulWidget {
  const SavedTick({super.key, required this.visible, required this.token});

  final bool visible;

  /// Bumped on every save, so saving the same field twice restarts the fade
  /// rather than leaving the first one to finish.
  final int token;

  @override
  State<SavedTick> createState() => _SavedTickState();
}

class _SavedTickState extends State<SavedTick> {
  static const _hold = Duration(milliseconds: 1400);
  static const _fade = Duration(milliseconds: 220);

  bool _shown = false;

  /// Held rather than fired and forgotten, so it can be cancelled on dispose —
  /// a pending timer outliving its widget is a leak in the app and an outright
  /// failure under `testWidgets`, which checks for exactly this.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _show();
  }

  @override
  void didUpdateWidget(SavedTick old) {
    super.didUpdateWidget(old);
    if (widget.visible && (!old.visible || old.token != widget.token)) {
      _show();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _show() {
    setState(() => _shown = true);
    _timer?.cancel();
    _timer = Timer(_hold, () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: _fade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: context.semantic.success,
          ),
          const SizedBox(width: Insets.xs),
          Flexible(
            child: Text(
              'Saved',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: context.semantic.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
