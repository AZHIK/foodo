import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/providers/reports_provider.dart';
import 'package:restaurant_pos/services/inventory_api_service.dart';
import 'package:restaurant_pos/services/pos_reports_api_service.dart';

import 'test_helpers/test_container.dart';

void main() {
  group('reports providers without a business context', () {
    test('every section is empty rather than demo data', () async {
      final container = newTestContainer();

      expect(await container.read(dailyTakingsProvider.future), isEmpty);
      expect(await container.read(itemMixProvider.future), isEmpty);
      expect(await container.read(staffPerformanceProvider.future), isEmpty);
      expect(await container.read(financeSummaryProvider.future), isNull);
      expect(await container.read(wasteSummaryProvider.future), isNull);
      expect(await container.read(productionSummaryProvider.future), isNull);
      expect(await container.read(stockValuationProvider.future), isNull);
      expect(container.read(resolvedItemMixProvider), isEmpty);
    });

    test('the date window defaults to the last 30 days', () {
      final container = newTestContainer();
      final filter = container.read(reportsDateFilterProvider);

      expect(filter.to, isNull);
      expect(
        DateTime.now().difference(filter.from!).inDays,
        inInclusiveRange(28, 31),
      );

      final rangeEnd = DateTime.utc(2026, 9, 30);
      container
          .read(reportsDateFilterProvider.notifier)
          .setRange(DateTime.utc(2026, 9, 1), rangeEnd);
      expect(
        container.read(reportsDateFilterProvider).to,
        rangeEnd,
      );
    });
  });

  group('report DTOs', () {
    test('DailyTakingsDayDto parses a day row', () {
      final day = DailyTakingsDayDto.fromJson({
        'date': '2026-09-14',
        'revenue': '150.00',
        'sales_count': 2,
        'avg_ticket': '75.00',
        'voided_count': 1,
        'refunded_count': 0,
      });

      expect(day.date, DateTime(2026, 9, 14));
      expect(day.revenue, Decimal.parse('150'));
      expect(day.voidedCount, 1);
    });

    test('ItemMixLineDto keeps ids unresolved', () {
      final line = ItemMixLineDto.fromJson({
        'item_id': 'item-1',
        'quantity': '3.000',
        'revenue': '30.00',
        'lines': 2,
      });

      expect(line.itemId, 'item-1');
      expect(line.quantity, Decimal.parse('3'));
    });

    test('FinanceSummaryDto keeps the net beside its parts', () {
      final summary = FinanceSummaryDto.fromJson({
        'sales_revenue': '200.00',
        'income_total': '30.00',
        'expense_total': '70.00',
        'net': '160.00',
        'expenses_by_category': [
          {'category': 'rent', 'total': '50.00'},
        ],
        'incomes_by_category': [],
      });

      expect(summary.net, Decimal.parse('160'));
      expect(summary.expensesByCategory.single.category, 'rent');
    });

    test('ProductionSummaryDto keeps the portioning gap', () {
      final dto = ProductionSummaryDto.fromJson({
        'runs': 2,
        'suggested_total': '15.000',
        'actual_total': '13.000',
        'over_portioned_by': '-2.000',
        'ingredients_consumed': [],
      });

      expect(dto.runs, 2);
      expect(dto.overPortionedBy, Decimal.parse('-2'));
    });

    test('StockValuationLineDto tolerates a null category', () {
      final line = StockValuationLineDto.fromJson({
        'category': null,
        'item_count': 3,
        'total_value': '10.000',
      });

      expect(line.category, isNull);
      expect(line.itemCount, 3);
    });
  });
}
