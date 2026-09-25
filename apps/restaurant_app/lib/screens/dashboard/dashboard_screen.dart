import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/breakpoints.dart';
import '../settings/store_switch_flow.dart';
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
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The offline-switch banner lives above the landing screen: it is the
    // first thing anyone sees at the start of a shift, which is exactly
    // when a pending store token matters.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StoreTokenBanner(),
        Expanded(
          child: context.isMobile
              ? const DashboardMobileScreen()
              : const DashboardDesktopScreen(),
        ),
      ],
    );
  }
}
