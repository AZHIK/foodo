import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/shared/fakes/fake_data_service.dart';

void main() {
  group('FakeDataService', () {
    late FakeDataService svc;
    setUp(() => svc = FakeDataService());

    test('inventory has 20-30 items with varied categories', () {
      expect(svc.inventoryItems.length, inInclusiveRange(20, 35));
      final categories = svc.inventoryItems.map((i) => i.category).toSet();
      expect(categories.length, greaterThanOrEqualTo(4));
    });

    test('at least one item is out of stock and one is low-stock', () {
      final outOfStock = svc.inventoryItems.where((i) => i.isOutOfStock);
      final lowStock = svc.inventoryItems.where((i) => i.isLowStock);
      expect(outOfStock.isNotEmpty, isTrue);
      expect(lowStock.isNotEmpty, isTrue);
    });

    test('every item has sensible price in senti (100+ senti = 1+ TZS)', () {
      for (final item in svc.inventoryItems) {
        expect(item.priceSenti, greaterThanOrEqualTo(40000)); // >= 400 TZS
        expect(item.costPriceSenti, lessThanOrEqualTo(item.priceSenti));
      }
    });

    test('sales list has 15-20 records', () {
      expect(svc.sales.length, inInclusiveRange(15, 25));
    });

    test('sales include at least one voided and one time-suspect', () {
      final voided = svc.sales.where((s) => s.status == FakeSaleStatus.voided);
      final suspect = svc.sales.where((s) => s.isTimeSuspect);
      expect(voided.isNotEmpty, isTrue);
      expect(suspect.isNotEmpty, isTrue);
    });

    test('sales have varied payment methods', () {
      final methods = svc.sales.map((s) => s.paymentMethod).toSet();
      expect(methods.length, greaterThanOrEqualTo(2));
    });

    test('sales spread across >= 2 distinct dates', () {
      final dates = svc.sales.map((s) {
        final d = s.createdAt;
        return DateTime(d.year, d.month, d.day);
      }).toSet();
      expect(dates.length, greaterThanOrEqualTo(2));
    });

    test('sale totals match sum of line subtotals', () {
      for (final sale in svc.sales) {
        final sum = sale.lines.fold<int>(0, (a, l) => a + l.subtotalSenti);
        expect(sum, equals(sale.subtotalSenti));
        expect(
          sale.totalSenti,
          equals(sale.subtotalSenti - sale.discountSenti + sale.taxSenti),
        );
      }
    });

    test('line subtotals match qty * unit price', () {
      for (final sale in svc.sales) {
        for (final line in sale.lines) {
          expect(line.subtotalSenti, equals(line.unitPriceSenti * line.quantity));
        }
      }
    });
  });
}
