/// Tests for `PendingSaleWriter` — the bridge from a placed `Order` onto the
/// `PendingSales`/`PendingSaleLineItems` outbox.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/sync/pending_sale_writer.dart';

void main() {
  group('PendingSaleWriter', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    Future<void> seedItem(String id, {String storeId = 'store-1'}) async {
      final now = DateTime.now();
      await database.into(database.cachedItems).insert(
            CachedItemsCompanion.insert(
              id: id,
              businessId: 'biz-1',
              businessLocationId: storeId,
              name: 'Pilau',
              unitOfMeasure: 'unit',
              reorderThreshold: Decimal.zero,
              reorderQuantity: Decimal.zero,
              itemType: 'sellable',
              createdAtServer: now,
              updatedAtServer: now,
              lastSeenAt: now,
              lastSyncedAt: now,
            ),
          );
    }

    Order order({String itemId = 'item-1'}) => Order(
          id: 'ORD-0001',
          lines: [
            OrderLine(
              itemId: itemId,
              name: 'Pilau',
              emoji: '📦',
              unitPrice: 10,
              quantity: 2,
            ),
          ],
          placedAt: DateTime(2026, 1, 2, 12),
          paymentType: PaymentType.cash,
          status: OrderStatus.paid,
          taxRate: 0.0825,
        );

    test('writes a sale and its line items when every item resolves', () async {
      await seedItem('item-1');

      final written = await PendingSaleWriter(database).writeIfMappable(
        order(),
        storeId: 'store-1',
      );

      expect(written, isTrue);

      final sales = await database.select(database.pendingSales).get();
      expect(sales, hasLength(1));
      expect(sales.single.storeId, 'store-1');
      expect(sales.single.status, 'completed');
      expect(sales.single.paymentMethod, 'cash');
      expect(sales.single.localOrderId, 'ORD-0001');

      final lineItems = await database.select(database.pendingSaleLineItems).get();
      expect(lineItems, hasLength(1));
      expect(lineItems.single.itemId, 'item-1');
      expect(lineItems.single.quantity, Decimal.fromInt(2));
      expect(lineItems.single.unitPrice, Decimal.parse('10.00'));
    });

    test('skips the whole sale when an item does not resolve', () async {
      // No item seeded at all — 'item-1' cannot resolve.
      final written = await PendingSaleWriter(database).writeIfMappable(
        order(),
        storeId: 'store-1',
      );

      expect(written, isFalse);
      expect(await database.select(database.pendingSales).get(), isEmpty);
      expect(await database.select(database.pendingSaleLineItems).get(), isEmpty);
    });

    test('skips when the item is cached for a different store', () async {
      await seedItem('item-1', storeId: 'store-2');

      final written = await PendingSaleWriter(database).writeIfMappable(
        order(),
        storeId: 'store-1',
      );

      expect(written, isFalse);
    });

    test('skips when the item has been archived', () async {
      await seedItem('item-1');
      await (database.update(database.cachedItems)
            ..where((row) => row.id.equals('item-1')))
          .write(const CachedItemsCompanion(isActive: Value(false)));

      final written = await PendingSaleWriter(database).writeIfMappable(
        order(),
        storeId: 'store-1',
      );

      expect(written, isFalse);
    });
  });
}
