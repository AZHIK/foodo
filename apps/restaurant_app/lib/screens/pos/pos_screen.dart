import 'package:flutter/material.dart';

import '../../theme/breakpoints.dart';
import 'pos_desktop_screen.dart';
import 'pos_mobile_screen.dart';

/// The order terminal.
///
/// This widget only picks the view: [PosMobileScreen] on phones, where the
/// ticket collapses to a bottom cart bar and sheet, and [PosDesktopScreen]
/// everywhere else, where it is a persistent panel beside the grid. The menu
/// side (search bar, category strip, item grid) is shared in
/// `pos_widgets.dart` so both views always show the same menu.
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? const PosMobileScreen()
        : const PosDesktopScreen();
  }
}
