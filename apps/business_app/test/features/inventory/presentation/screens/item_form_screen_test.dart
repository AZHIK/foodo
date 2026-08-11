import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:foodlink_business/app/router/app_routes.dart';
import 'package:foodlink_business/core/constants/app_dimensions.dart';
import 'package:foodlink_business/features/inventory/presentation/screens/item_form_screen.dart';
import 'package:foodlink_business/shared/fakes/fake_data_service.dart';

Widget _buildTestApp() {
  return const ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(AppDimensions.breakpointDesktop, 1000)),
        child: ItemFormScreen(mode: ItemFormMode.add),
      ),
    ),
  );
}

void main() {
  group('ItemFormScreen', () {
    testWidgets('validation rejects empty name and zero selling price',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Item'));
      await tester.tap(find.text('Save Item'));
      await tester.pumpAndSettle();

      expect(find.text('Item name is required'), findsOneWidget);
      expect(find.text('Category is required'), findsOneWidget);

      // Enter a name + category but leave the selling price at zero.
      await tester.enterText(find.byType(TextField).at(0), 'Mbege Fresh');
      await tester.enterText(find.byType(TextField).at(1), 'Drinks');
      await tester.ensureVisible(find.text('Save Item'));
      await tester.tap(find.text('Save Item'));
      await tester.pumpAndSettle();

      expect(find.text('Selling price must be greater than zero'),
          findsOneWidget);
    });

    testWidgets('clamps a negative reorder threshold to zero', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Reorder Threshold is the 6th TextField (index 5).
      await tester.enterText(find.byType(TextField).at(5), '-5');
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('submits a valid new item and navigates back to the list',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: AppRoutes.inventoryNew,
        routes: [
          GoRoute(
            path: AppRoutes.inventory,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('Inventory Screen'))),
          ),
          GoRoute(
            path: AppRoutes.inventoryNew,
            builder: (_, _) => const ItemFormScreen(mode: ItemFormMode.add),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Mbege Fresh');
      await tester.enterText(find.byType(TextField).at(1), 'Drinks');
      await tester.enterText(find.byType(TextField).at(2), '15000');

      await tester.ensureVisible(find.text('Save Item'));
      await tester.tap(find.text('Save Item'));
      await tester.pumpAndSettle();

      expect(find.text('Inventory Screen'), findsOneWidget);

      final items = container.read(fakeInventoryProvider);
      final added = items.where((i) => i.name == 'Mbege Fresh').firstOrNull;
      expect(added, isNotNull);
      expect(added!.priceSenti, 1500000);
      expect(added.category, 'Drinks');
    });
  });
}
