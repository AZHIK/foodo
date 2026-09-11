import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/sync/catalog_sync_service.dart';
import 'package:restaurant_pos/sync/fake_inventory_catalog_api.dart';
import 'package:restaurant_pos/sync/inventory_catalog_api.dart';

void main() {
  group('CatalogSyncService', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('reactivates cached items returned by the catalog API', () async {
      final now = DateTime.now();
      const itemId = 'item-uuid-1';
      const storeId = 'store-uuid-1';

      await database
          .into(database.cachedItems)
          .insert(
            CachedItemsCompanion.insert(
              id: itemId,
              businessId: 'business-uuid-1',
              businessLocationId: storeId,
              name: 'Tomato',
              unitOfMeasure: 'kg',
              unitId: const Value('unit-kg'),
              reorderThreshold: Decimal.fromInt(10),
              reorderQuantity: Decimal.fromInt(20),
              unitCost: Value(Decimal.parse('1.25')),
              itemType: 'raw_material',
              isActive: const Value(false),
              createdAtServer: now,
              updatedAtServer: now,
              lastSeenAt: now,
              lastSyncedAt: now,
            ),
          );

      final service = CatalogSyncService(
        db: database,
        api: FakeInventoryCatalogApi(
          overrideCatalog: [
            CatalogItemDto(
              id: itemId,
              businessId: 'business-uuid-1',
              storeId: storeId,
              name: 'Tomato',
              unitId: 'unit-kg',
              reorderThreshold: Decimal.fromInt(10),
              reorderQuantity: Decimal.fromInt(20),
              unitCost: Decimal.parse('1.25'),
              allowNegativeStock: false,
              itemType: 'raw_material',
              isActive: true,
              createdAt: now,
              updatedAt: now.add(const Duration(seconds: 1)),
            ),
          ],
        ),
      );

      await service.syncCatalog(storeId: storeId);

      final item = await (database.select(
        database.cachedItems,
      )..where((row) => row.id.equals(itemId))).getSingle();
      expect(item.isActive, isTrue);
    });
  });
}
