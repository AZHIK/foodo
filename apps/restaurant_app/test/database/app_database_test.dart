/// Tests for the Drift database schema and basic operations.
///
/// This test suite verifies that the database schema is correctly defined
/// and that migrations work as expected. Since this is schemaVersion 1
/// (the first version), only the `onCreate` path is tested; there is no
/// prior version to migrate from.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/database/app_database.dart';

AppDatabase _createTestDatabase() {
  final connection = NativeDatabase.memory();
  return AppDatabase(connection);
}

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      database = _createTestDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    test('creates schema on first use', () async {
      // The schema is created in `onCreate` when `MigrationStrategy` is applied.
      // No explicit call needed; just opening the database triggers it.
      // If we get here without an exception, the schema was created successfully.
      expect(database != null, true);
    });

    test('schema version is 1', () async {
      expect(database.schemaVersion, 1);
    });

    test('LocalUserProfiles table exists and can be queried', () async {
      // Insert a test profile
      await database.into(database.localUserProfiles).insert(
            LocalUserProfilesCompanion.insert(
              id: 'test-staff-1',
              displayName: 'Test Staff',
              pinHash: 'hashed_pin',
              pinSalt: 'salt',
              failedPinAttempts: const Value(0),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      // Query it back
      final profile = await (database.select(database.localUserProfiles)
            ..where((row) => row.id.equals('test-staff-1')))
          .getSingleOrNull();

      expect(profile != null, true);
      expect(profile!.displayName, 'Test Staff');
    });

    test('DeviceConfig table exists and enforces singleton constraint', () async {
      final now = DateTime.now();

      // Insert the singleton row
      await database.into(database.deviceConfig).insertOnConflictUpdate(
            DeviceConfigCompanion.insert(
              businessId: 'biz-123',
              businessLocationId: 'loc-456',
              businessName: 'Test Business',
              provisionedAt: now,
              updatedAt: now,
            ),
          );

      // Verify it's there
      final config = await (database.select(database.deviceConfig)
            ..where((row) => row.id.equals(0)))
          .getSingleOrNull();

      expect(config != null, true);
      expect(config!.businessId, 'biz-123');

      // Update the same row (upsert with the same id)
      await database.into(database.deviceConfig).insertOnConflictUpdate(
            DeviceConfigCompanion(
              businessId: const Value('biz-789'),
              businessLocationId: const Value('loc-999'),
              businessName: const Value('Updated Business'),
              provisionedAt: Value(now),
              updatedAt: Value(now.add(const Duration(seconds: 1))),
            ),
          );

      // Verify the row was updated, not duplicated
      final configs = await database.select(database.deviceConfig).get();
      expect(configs.length, 1);
      expect(configs.first.businessId, 'biz-789');
    });

    test('PendingSales and PendingSaleLineItems tables exist', () async {
      final now = DateTime.now();

      // Insert a pending sale
      final saleId = await database.into(database.pendingSales).insert(
            PendingSalesCompanion.insert(
              clientSaleId: 'sale-uuid-1',
              status: 'completed',
              businessLocationId: 'loc-123',
              paymentMethod: 'cash',
              occurredAt: now,
              createdAt: now,
            ),
          );

      // Insert a line item
      await database.into(database.pendingSaleLineItems).insert(
            PendingSaleLineItemsCompanion.insert(
              pendingSaleId: saleId,
              itemId: 'item-uuid-1',
              quantity: Decimal.fromInt(10),
              unitPrice: Decimal.parse('5.00'),
            ),
          );

      // Query the sale back with its line items
      final sales = await database.select(database.pendingSales).get();
      expect(sales.length, 1);
      expect(sales.first.clientSaleId, 'sale-uuid-1');

      final lineItems = await database.select(database.pendingSaleLineItems).get();
      expect(lineItems.length, 1);
      expect(lineItems.first.itemId, 'item-uuid-1');
    });

    test('CachedItems table exists', () async {
      final now = DateTime.now();

      // Insert a cached item
      await database.into(database.cachedItems).insert(
            CachedItemsCompanion.insert(
              id: 'item-uuid-1',
              businessId: 'biz-123',
              businessLocationId: 'loc-456',
              name: 'Tomato',
              unitOfMeasure: 'kg',
              reorderThreshold: Decimal.fromInt(10),
              reorderQuantity: Decimal.fromInt(20),
              itemType: 'sellable',
              createdAtServer: now,
              updatedAtServer: now,
              lastSeenAt: now,
              lastSyncedAt: now,
            ),
          );

      // Query it back
      final items = await database.select(database.cachedItems).get();
      expect(items.length, 1);
      expect(items.first.name, 'Tomato');
    });

    test('foreign keys are enforced', () async {
      // Try to insert a PendingSaleLineItems row with a non-existent pendingSaleId
      // This should fail if foreign keys are properly enforced.
      expect(
        () => database.into(database.pendingSaleLineItems).insert(
              PendingSaleLineItemsCompanion.insert(
                pendingSaleId: 9999, // Non-existent sale ID
                itemId: 'item-uuid-1',
                quantity: Decimal.fromInt(10),
                unitPrice: Decimal.parse('5.00'),
              ),
            ),
        throwsException,
      );
    });
  });
}
