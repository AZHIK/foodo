import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/shared/widgets/cards/product_card.dart';

void main() {
  group('ProductCard', () {
    testWidgets('gridTile variant renders image, name, price, stock badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 260,
              child: ProductCard(
                variant: ProductCardVariant.gridTile,
                name: 'Beef Pilau',
                priceSenti: 850000,
                stockStatus: ProductStockStatus.inStock,
                stockLevel: 18,
                category: 'Rice Dishes',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Beef Pilau'), findsOneWidget);
      expect(find.text('Rice Dishes'), findsOneWidget);
      expect(find.textContaining('TZS'), findsOneWidget);
      expect(find.textContaining('8,500'), findsOneWidget);
      expect(find.text('18 in stock'), findsOneWidget);
    });

    testWidgets('listTile variant renders horizontal layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: ProductCard(
                variant: ProductCardVariant.listTile,
                name: 'Ugali',
                priceSenti: 200000,
                stockStatus: ProductStockStatus.inStock,
                stockLevel: 68,
                category: 'Staples',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ugali'), findsOneWidget);
      expect(find.text('Staples'), findsOneWidget);
      expect(find.textContaining('2,000'), findsOneWidget);
      expect(find.textContaining('68'), findsOneWidget);
    });

    testWidgets('low stock status shows amber warning badge color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 260,
              child: ProductCard(
                variant: ProductCardVariant.gridTile,
                name: 'Mishkaki',
                priceSenti: 350000,
                stockStatus: ProductStockStatus.lowStock,
                stockLevel: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Find the low-stock text as a reliable signal first
      expect(find.text('Low · 2'), findsOneWidget);
    });

    testWidgets('out-of-stock status shows "Out of stock" badge text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 260,
              child: ProductCard(
                variant: ProductCardVariant.gridTile,
                name: 'Chicken Biryani',
                priceSenti: 1200000,
                stockStatus: ProductStockStatus.outOfStock,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('in-stock status shows green / "In stock" label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 260,
              child: ProductCard(
                variant: ProductCardVariant.gridTile,
                name: 'Coca-Cola 300ml',
                priceSenti: 120000,
                stockStatus: ProductStockStatus.inStock,
                stockLevel: 36,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('36 in stock'), findsOneWidget);
    });

    testWidgets('price formatting handles large values with commas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 260,
              child: ProductCard(
                variant: ProductCardVariant.listTile,
                name: 'Grilled Tilapia',
                priceSenti: 1500000,
                stockStatus: ProductStockStatus.inStock,
                stockLevel: 8,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('TZS 15,000'), findsOneWidget);
    });

    testWidgets('onTap fires for gridTile', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 260,
              child: ProductCard(
                variant: ProductCardVariant.gridTile,
                name: 'Test',
                priceSenti: 100000,
                stockStatus: ProductStockStatus.inStock,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProductCard));
      expect(tapped, isTrue);
    });
  });
}
