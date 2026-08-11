import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_dimensions.dart';
import 'package:foodlink_business/shared/widgets/app_responsive_layout.dart';

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
    const MaterialApp(
      home: AppResponsiveLayout(
        mobile: Text('MOBILE_VIEW'),
        tablet: Text('TABLET_VIEW'),
        desktop: Text('DESKTOP_VIEW'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppResponsiveLayout', () {
    testWidgets('picks the mobile view below the tablet breakpoint',
        (tester) async {
      await _pumpAtWidth(tester, 390);
      expect(find.text('MOBILE_VIEW'), findsOneWidget);
      expect(find.text('TABLET_VIEW'), findsNothing);
      expect(find.text('DESKTOP_VIEW'), findsNothing);
    });

    testWidgets('picks the tablet view between tablet and desktop breakpoints',
        (tester) async {
      await _pumpAtWidth(tester, AppDimensions.breakpointDesktop - 1);
      expect(find.text('TABLET_VIEW'), findsOneWidget);
      expect(find.text('MOBILE_VIEW'), findsNothing);
    });

    testWidgets('picks the desktop view at or above the desktop breakpoint',
        (tester) async {
      await _pumpAtWidth(tester, AppDimensions.breakpointDesktop + 100);
      expect(find.text('DESKTOP_VIEW'), findsOneWidget);
      expect(find.text('TABLET_VIEW'), findsNothing);
    });

    testWidgets('falls back to the tablet view when desktop is omitted',
        (tester) async {
      tester.view.physicalSize =
          const Size(AppDimensions.breakpointDesktop + 200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: AppResponsiveLayout(
            mobile: Text('MOBILE_VIEW'),
            tablet: Text('TABLET_VIEW'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TABLET_VIEW'), findsOneWidget);
    });

    testWidgets('exposes correct breakpoint helpers', (tester) async {
      expect(AppResponsiveLayout.isMobileWidth(390), isTrue);
      expect(AppResponsiveLayout.isMobileWidth(600), isFalse);
      expect(AppResponsiveLayout.isTabletWidth(800), isTrue);
      expect(AppResponsiveLayout.isDesktopWidth(1200), isTrue);

      expect(
        AppResponsiveLayout.horizontalPaddingFor(390),
        AppDimensions.spaceMD,
      );
      expect(
        AppResponsiveLayout.horizontalPaddingFor(1200),
        AppDimensions.spaceXXXL,
      );
      expect(AppResponsiveLayout.contentMaxWidthFor(1200), 480);
      expect(AppResponsiveLayout.contentMaxWidthFor(390), double.infinity);
    });
  });
}
