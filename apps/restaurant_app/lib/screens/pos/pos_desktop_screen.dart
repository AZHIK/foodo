import 'package:flutter/material.dart';

import '../../theme/breakpoints.dart';
import '../../widgets/pos/order_summary_panel.dart';
import '../../widgets/pos/pos_top_bar.dart';
import 'pos_widgets.dart';

/// The order terminal as a desktop and tablet experience.
///
/// The ticket is a persistent panel beside the grid — a counter terminal is
/// a fixed installation, and the cashier's eyes should never have to go
/// looking for the running order.
class PosDesktopScreen extends StatelessWidget {
  const PosDesktopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Which arrangement to use is a property of the window, not of this
    // box. Measuring locally would let the navigation rail's own width
    // demote a 1024px desktop into the tablet layout. The grid still
    // sizes its columns from the box it actually gets, below.
    final form = context.formFactor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        right: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PosTopBar(form: form),
                  PosCategoryStrip(form: form),
                  Expanded(child: PosMenuGrid(form: form)),
                ],
              ),
            ),
            OrderSummaryPanel(width: Layout.orderPanel(form)),
          ],
        ),
      ),
    );
  }
}
