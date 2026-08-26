import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shakes its child once each time [token] changes.
///
/// The app's single rejection gesture. The PIN dots and the OTP row each had
/// their own copy of this before; the vocabulary was always shared, so the
/// implementation may as well be — a rejection that reads differently in two
/// places is one the eye has to learn twice.
class Shake extends StatefulWidget {
  const Shake({
    super.key,
    required this.token,
    required this.child,
    this.amplitude = 9,
  });

  /// Bumped by the parent on every rejection. A counter rather than a bool, so
  /// three wrong entries in a row shake three times instead of once.
  final int token;

  /// Peak horizontal travel in logical pixels. The OTP row is wider than the
  /// PIN dots and reads better slightly gentler.
  final double amplitude;

  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.token > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Three decaying swings. A single sweep would read as a slide; it is the
  /// decay that makes it read as a rejection.
  double _swing(double t) {
    if (t == 0 || t >= 1) return 0;
    const cycles = 3;
    return math.sin(t * cycles * 2 * math.pi) * widget.amplitude * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(_swing(_controller.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
