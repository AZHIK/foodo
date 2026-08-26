import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/constants/app_dimensions.dart';
import 'package:foodlink_business/features/pos/presentation/screens/pos/pos_desktop_layout.dart';
import 'package:foodlink_business/features/pos/presentation/screens/pos/pos_mobile_layout.dart';
import 'package:foodlink_business/features/pos/presentation/screens/pos/pos_tablet_layout.dart';
import 'package:foodlink_business/features/pos/presentation/screens/pos_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';

Widget _buildApp({required Size size, required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: const PosScreen(),
        ),
      ),
    ),
  );
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      fakeInventoryProvider.overrideWith((ref) {
        final notifier = FakeInventoryNotifier(FakeDataService());
        notifier.loadItems(_items);
        return notifier;
      }),
      fakeSalesProvider.overrideWith((ref) {
        final notifier = FakeSalesNotifier(FakeDataService());
        notifier.loadSales(const []);
        return notifier;
      }),
    ],
  );
}

final _items = [
  FakeInventoryItem(
    id: 'item_1',
    name: 'Ugali',
    category: 'Staples',
    sku: 'STA-001',
    priceSenti: 200000,
    stockLevel: 20,
    reorderThreshold: 4,
    costPriceSenti: 100000,
    unit: 'pcs',
    barcode: '111',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  FakeInventoryItem(
    id: 'item_2',
    name: 'Soda',
    category: 'Drinks',
    sku: 'DRI-001',
    priceSenti: 100000,
    stockLevel: 30,
    reorderThreshold: 5,
    costPriceSenti: 50000,
    unit: 'pcs',
    barcode: '222',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
];

void main() {
  testWidgets('adding items updates running total', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(
        size: const Size(AppDimensions.breakpointDesktop, 900),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete Sale'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );

    await tester.tap(find.text('Ugali'));
    await tester.pumpAndSettle();

    // Desktop's cart panel header reads "Current Sale" (reference-matched
    // restyle) — the shared tablet/mobile panel still says "Current Ticket".
    expect(find.text('Current Sale'), findsOneWidget);
    expect(find.text('TZS 2,360'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNotNull,
    );
  });

  testWidgets('adjusting quantity updates total', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(
        size: const Size(AppDimensions.breakpointDesktop, 900),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Soda'));
    await tester.pumpAndSettle();
    expect(find.text('TZS 1,180'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    expect(find.text('TZS 2,360'), findsOneWidget);
  });

  testWidgets('phone width renders the mobile layout', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(size: const Size(390, 900), container: container),
    );
    await tester.pumpAndSettle();

    // Segmented Browse/Cart + the screen's own AppBar; no side-by-side
    // ticket panel at this width.
    expect(find.byType(PosMobileLayout), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Cart (0)'), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Current Sale'), findsNothing);
  });

  testWidgets('mobile checkout bar tracks the running total', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(size: const Size(390, 900), container: container),
    );
    await tester.pumpAndSettle();

    // Complete Sale lives only in the persistent bottom bar on phones, and
    // is disabled until the ticket has a line.
    final completeSale = find.widgetWithText(FilledButton, 'Complete Sale');
    expect(completeSale, findsOneWidget);
    expect(tester.widget<FilledButton>(completeSale).onPressed, isNull);

    await tester.tap(find.text('Ugali'));
    await tester.pumpAndSettle();

    // Adding an item keeps the cashier on Browse — the bar carries the
    // total instead of forcing a tab switch per item.
    expect(find.text('Cart (1)'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(tester.widget<FilledButton>(completeSale).onPressed, isNotNull);
  });

  testWidgets('tablet width renders the dense two-panel layout', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(
        size: const Size(AppDimensions.breakpointTablet + 40, 900),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PosTabletLayout), findsOneWidget);
    expect(find.text('Current Sale'), findsOneWidget);
    // Short-label action; the full "Sales History" label is desktop-only.
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Sales History'), findsNothing);
    expect(find.text('Browse'), findsNothing);
  });

  testWidgets('desktop width renders the roomy two-panel layout', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(
        size: const Size(AppDimensions.breakpointDesktop, 900),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PosDesktopLayout), findsOneWidget);
    expect(find.text('Point of Sale (POS)'), findsOneWidget);
    expect(find.text('Current Sale'), findsOneWidget);
    expect(find.text('Sales History'), findsOneWidget);
    expect(find.text('Browse'), findsNothing);
  });

  testWidgets('cart survives crossing the tablet/desktop breakpoint', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _buildApp(
        size: const Size(AppDimensions.breakpointDesktop, 900),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ugali'));
    await tester.pumpAndSettle();
    expect(find.text('TZS 2,360'), findsOneWidget);

    // Sale state lives in PosScreen, not in any one layout, so resizing
    // across a breakpoint swaps the tree without dropping the ticket.
    await tester.pumpWidget(
      _buildApp(
        size: const Size(AppDimensions.breakpointTablet + 40, 900),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PosTabletLayout), findsOneWidget);
    expect(find.text('TZS 2,360'), findsOneWidget);
  });
}
