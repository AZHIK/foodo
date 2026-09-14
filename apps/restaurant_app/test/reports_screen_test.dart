import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/models/permission.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/permissions_provider.dart';
import 'package:restaurant_pos/providers/reports_provider.dart';
import 'package:restaurant_pos/screens/reports/reports_screen.dart';
import 'package:restaurant_pos/services/pos_reports_api_service.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'test_helpers/test_container.dart';

ItemMixLineDto mixLine(String itemId, String qty, String revenue) =>
    ItemMixLineDto(
      itemId: itemId,
      quantity: Decimal.parse(qty),
      revenue: Decimal.parse(revenue),
      lines: 1,
    );

InventoryItem catalogItem(String id, String name) => InventoryItem(
      id: 'local-$id',
      sku: 'SKU-$id',
      name: name,
      categoryId: 'mains',
      emoji: '🍚',
      stock: 5,
      reorderLevel: 1,
      unitCost: 2,
      catalogItemId: id,
    );

class _MixWithLines extends ItemMixNotifier {
  @override
  Future<List<ItemMixLineDto>> build() async => [
        mixLine('backend-burger', '3', '30.00'),
        mixLine('backend-ghost', '1', '5.00'),
      ];
}

/// Pumps the reports screen with the mix lines and catalog overridden —
/// no business context needed since nothing here fetches.
Future<void> pumpReports(
  WidgetTester tester, {
  Set<String> permissions = const {},
}) async {
  final container = newTestContainer(
    extraOverrides: [
      itemMixProvider.overrideWith(_MixWithLines.new),
      inventoryItemsListProvider.overrideWithValue([
        catalogItem('backend-burger', 'House Burger'),
      ]),
      hasPermissionProvider.overrideWith(
        (ref, code) => permissions.contains(code),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ReportsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ReportsScreen', () {
    testWidgets('sections render with resolved names', (tester) async {
      await pumpReports(tester);

      expect(find.text('Daily takings'), findsOneWidget);
      expect(find.text('Item mix'), findsOneWidget);
      expect(find.text('Staff performance'), findsOneWidget);
      // Catalog join resolves the known id; the unknown one stays honest.
      expect(find.text('House Burger'), findsOneWidget);
      expect(find.text('Unknown item'), findsOneWidget);
      // The valuation section sits at the bottom of a lazily-built ListView,
      // so it only enters the tree once scrolled into view.
      await tester.scrollUntilVisible(
        find.text('Value by category'),
        300,
      );
      await tester.pumpAndSettle();
      expect(find.text('Value by category'), findsOneWidget);
    });

    testWidgets('export actions need the export permission', (tester) async {
      await pumpReports(tester);
      expect(find.text('Export PDF'), findsNothing);

      await pumpReports(
        tester,
        permissions: {AppPermissions.reportsExport},
      );
      expect(find.text('Export PDF'), findsWidgets);
    });
  });
}
