import 'package:flutter/material.dart';

import '../../theme/breakpoints.dart';
import 'dashboard_desktop_screen.dart';
import 'dashboard_mobile_screen.dart';

/// The landing screen.
///
/// Deliberately the warmest surface in the app: tinted KPI cards, real charts
/// and a soft-shadowed card treatment, rather than the dense neutral tables
/// that suit Inventory, Sales and Staff. It is the first thing anyone sees at
/// the start of a shift, and it is read at a glance rather than worked in.
///
/// This widget only picks the view: [DashboardMobileScreen] on phones,
/// [DashboardDesktopScreen] everywhere else. Shared pieces (greeting, KPI
/// cards, charts, lists) live in `dashboard_widgets.dart` so the two views
/// can never disagree about what the numbers say — only how they are laid
/// out. Tablet renders the desktop view, whose rows reflow through their own
/// [LayoutBuilder] thresholds at mid widths.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? const DashboardMobileScreen()
        : const DashboardDesktopScreen();
  }
}
