import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema version', () {
    test('is 2 (Stage 3 lockout columns)', () {
      expect(db.schemaVersion, equals(2));
    });
  });

  group('LocalUserProfiles', () {
    test('insert and read back', () async {
      final now = DateTime.now();
      await db.into(db.localUserProfiles).insert(LocalUserProfilesCompanion(
            userId: const Value('user_abc'),
            phone: const Value('+233501234567'),
            displayName: const Value('Ama'),
            pinHash: const Value('argon2_hash_placeholder'),
            activeBusinessId: const Value('biz_001'),
            lastLoginAt: Value(now),
            isCurrentlyActive: const Value(true),
          ));

      final rows = await db.select(db.localUserProfiles).get();
      expect(rows.length, equals(1));
      expect(rows.first.userId, equals('user_abc'));
      expect(rows.first.phone, equals('+233501234567'));
      expect(rows.first.displayName, equals('Ama'));
      expect(rows.first.activeBusinessId, equals('biz_001'));
      expect(rows.first.isCurrentlyActive, isTrue);
      expect(rows.first.lastLoginAt.difference(now).inSeconds, equals(0));
    });

    test('isCurrentlyActive defaults to false', () async {
      await db.into(db.localUserProfiles).insert(LocalUserProfilesCompanion(
            userId: const Value('user_def'),
            phone: const Value('+233509876543'),
            displayName: const Value('Kofi'),
            pinHash: const Value('placeholder'),
            activeBusinessId: const Value(null),
            lastLoginAt: Value(DateTime.now()),
          ));

      final rows = await db.select(db.localUserProfiles).get();
      expect(rows.first.isCurrentlyActive, isFalse);
    });

    test('pinAttemptCount defaults to 0 and pinLockedUntil to null', () async {
      await db.into(db.localUserProfiles).insert(LocalUserProfilesCompanion(
            userId: const Value('user_ghi'),
            phone: const Value('+233507779999'),
            displayName: const Value('Esi'),
            pinHash: const Value('placeholder'),
            activeBusinessId: const Value(null),
            lastLoginAt: Value(DateTime.now()),
          ));

      final rows = await db.select(db.localUserProfiles).get();
      expect(rows.first.pinAttemptCount, equals(0));
      expect(rows.first.pinLockedUntil, isNull);
    });

    test('pinAttemptCount and pinLockedUntil round-trip', () async {
      final lockedUntil = DateTime.now().add(const Duration(days: 1));
      await db.into(db.localUserProfiles).insert(LocalUserProfilesCompanion(
            userId: const Value('user_jkl'),
            phone: const Value('+233507778888'),
            displayName: const Value('Yaw'),
            pinHash: const Value('placeholder'),
            activeBusinessId: const Value(null),
            lastLoginAt: Value(DateTime.now()),
            pinAttemptCount: const Value(5),
            pinLockedUntil: Value(lockedUntil),
          ));

      final rows = await db.select(db.localUserProfiles).get();
      expect(rows.first.pinAttemptCount, equals(5));
      expect(
        rows.first.pinLockedUntil!.difference(lockedUntil).inSeconds,
        equals(0),
      );
    });
  });

  group('CachedBusinessContexts', () {
    test('insert and read StringListConverter columns', () async {
      await db.into(db.cachedBusinessContexts).insert(
          CachedBusinessContextsCompanion(
            businessId: const Value('biz_001'),
            businessName: const Value('Test Eatery'),
            displayName: const Value('Test Eatery Ltd'),
            phone: const Value('+233501234567'),
            email: const Value('test@example.com'),
            address: const Value('Accra, Ghana'),
            currencyCode: const Value('GHS'),
            roleNames: const Value(['admin', 'cashier']),
            permissions: const Value(['pos:create', 'inventory:read']),
            cachedAt: Value(DateTime.now()),
          ));

      final rows = await db.select(db.cachedBusinessContexts).get();
      expect(rows.length, equals(1));
      expect(rows.first.businessName, equals('Test Eatery'));
      expect(rows.first.roleNames, equals(['admin', 'cashier']));
      expect(rows.first.permissions, equals(['pos:create', 'inventory:read']));
      expect(rows.first.currencyCode, equals('GHS'));
    });
  });

  group('CachedItems', () {
    test('insert and read numeric unitPrice without floating-point drift',
        () async {
      const testPrice = 12345;
      await db.into(db.cachedItems).insert(CachedItemsCompanion(
            itemId: const Value('item_001'),
            businessId: const Value('biz_001'),
            name: const Value('Jollof Rice'),
            category: const Value('Meals'),
            unit: const Value('plate'),
            unitPrice: const Value(testPrice),
            stockOnHand: const Value(50),
            cachedAt: Value(DateTime.now()),
            isAvailable: const Value(true),
          ));

      final rows = await db.select(db.cachedItems).get();
      expect(rows.first.unitPrice, equals(testPrice));
    });

    test('stockOnHand defaults to 0', () async {
      await db.into(db.cachedItems).insert(CachedItemsCompanion(
            itemId: const Value('item_002'),
            businessId: const Value('biz_001'),
            name: const Value('Fanta'),
            category: const Value('Drinks'),
            unit: const Value('bottle'),
            unitPrice: const Value(500),
            cachedAt: Value(DateTime.now()),
          ));

      final rows = await db.select(db.cachedItems).get();
      expect(rows.first.stockOnHand, equals(0));
    });

    test('multiple items round-trip without drift', () async {
      for (var i = 0; i < 5; i++) {
        await db.into(db.cachedItems).insert(CachedItemsCompanion(
              itemId: Value('item_$i'),
              businessId: const Value('biz_001'),
              name: Value('Item $i'),
              category: const Value('Test'),
              unit: const Value('pc'),
              unitPrice: Value(i * 100 + 1),
              cachedAt: Value(DateTime.now()),
            ));
      }

      final rows = await db.select(db.cachedItems).get();
      expect(rows.length, equals(5));

      final prices = rows.map((r) => r.unitPrice).toSet();
      expect(prices, contains(1));
      expect(prices, contains(101));
      expect(prices, contains(201));
    });
  });

  group('PendingSales + PendingSaleLineItems', () {
    test('insert pending sale and verify deviceSequence', () async {
      await db.into(db.pendingSales).insert(PendingSalesCompanion(
            clientSaleId: const Value('sale_001'),
            businessId: const Value('biz_001'),
            userId: const Value('user_abc'),
            deviceSequence: const Value(42),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final rows = await db.select(db.pendingSales).get();
      expect(rows.first.clientSaleId, equals('sale_001'));
      expect(rows.first.deviceSequence, equals(42));
      expect(rows.first.status, equals('pending'));
    });

    test('status defaults to pending', () async {
      await db.into(db.pendingSales).insert(PendingSalesCompanion(
            clientSaleId: const Value('sale_002'),
            businessId: const Value('biz_001'),
            userId: const Value('user_abc'),
            deviceSequence: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final rows = await db.select(db.pendingSales).get();
      expect(rows.first.status, equals('pending'));
    });

    test('insert line items referencing a pending sale and cached items',
        () async {
      await db.into(db.pendingSales).insert(PendingSalesCompanion(
            clientSaleId: const Value('sale_003'),
            businessId: const Value('biz_001'),
            userId: const Value('user_abc'),
            deviceSequence: const Value(3),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.cachedItems).insert(CachedItemsCompanion(
            itemId: const Value('item_ref'),
            businessId: const Value('biz_001'),
            name: const Value('Ref Item'),
            category: const Value('Test'),
            unit: const Value('pc'),
            unitPrice: const Value(1000),
            cachedAt: Value(DateTime.now()),
          ));

      await db.into(db.pendingSaleLineItems).insert(
          PendingSaleLineItemsCompanion(
            clientSaleId: const Value('sale_003'),
            itemId: const Value('item_ref'),
            quantity: const Value(2),
            unitPriceAtSale: const Value(1000),
            createdAt: Value(DateTime.now()),
          ));

      final lines = await db.select(db.pendingSaleLineItems).get();
      expect(lines.length, equals(1));
      expect(lines.first.clientSaleId, equals('sale_003'));
      expect(lines.first.itemId, equals('item_ref'));
      expect(lines.first.quantity, equals(2));
      expect(lines.first.unitPriceAtSale, equals(1000));
      expect(lines.first.id, isNotNull);
    });

    test('line item auto-increment id is unique', () async {
      await db.into(db.pendingSales).insert(PendingSalesCompanion(
            clientSaleId: const Value('sale_a'),
            businessId: const Value('biz_001'),
            userId: const Value('user_abc'),
            deviceSequence: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.pendingSales).insert(PendingSalesCompanion(
            clientSaleId: const Value('sale_b'),
            businessId: const Value('biz_001'),
            userId: const Value('user_abc'),
            deviceSequence: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.cachedItems).insert(CachedItemsCompanion(
            itemId: const Value('item_a'),
            businessId: const Value('biz_001'),
            name: const Value('A'),
            category: const Value('Test'),
            unit: const Value('pc'),
            unitPrice: const Value(100),
            cachedAt: Value(DateTime.now()),
          ));

      for (final saleId in ['sale_a', 'sale_b']) {
        await db.into(db.pendingSaleLineItems).insert(
            PendingSaleLineItemsCompanion(
              clientSaleId: Value(saleId),
              itemId: const Value('item_a'),
              quantity: const Value(1),
              unitPriceAtSale: const Value(100),
              createdAt: Value(DateTime.now()),
            ));
      }

      final lines = await db.select(db.pendingSaleLineItems).get();
      expect(lines.length, equals(2));
      expect(lines[0].id, isNot(equals(lines[1].id)));
    });
  });

  group('numeric round-trip', () {
    test('unitPrice micro-units survive insert/read without float drift',
        () async {
      const testValues = [1, 99, 100, 1000, 12345, 999999, 0];

      for (var i = 0; i < testValues.length; i++) {
        await db.into(db.cachedItems).insert(CachedItemsCompanion(
              itemId: Value('numeric_$i'),
              businessId: const Value('biz_001'),
              name: Value('Price item $i'),
              category: const Value('Numeric'),
              unit: const Value('ea'),
              unitPrice: Value(testValues[i]),
              cachedAt: Value(DateTime.now()),
            ));
      }

      final rows = await db.select(db.cachedItems).get();
      final readPrices =
          rows.map((r) => r.unitPrice).toSet();
      expect(readPrices, unorderedEquals(testValues));
    });

    test('unitPriceAtSale micro-units survive insert/read without float drift',
        () async {
      await db.into(db.pendingSales).insert(PendingSalesCompanion(
            clientSaleId: const Value('price_test'),
            businessId: const Value('biz_001'),
            userId: const Value('user'),
            deviceSequence: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.cachedItems).insert(CachedItemsCompanion(
            itemId: const Value('price_item'),
            businessId: const Value('biz_001'),
            name: const Value('Test'),
            category: const Value('Numeric'),
            unit: const Value('ea'),
            unitPrice: const Value(500),
            cachedAt: Value(DateTime.now()),
          ));

      const testPrice = 12345;
      await db.into(db.pendingSaleLineItems).insert(
          PendingSaleLineItemsCompanion(
            clientSaleId: const Value('price_test'),
            itemId: const Value('price_item'),
            quantity: const Value(1),
            unitPriceAtSale: const Value(testPrice),
            createdAt: Value(DateTime.now()),
          ));

      final lines = await db.select(db.pendingSaleLineItems).get();
      expect(lines.first.unitPriceAtSale, equals(testPrice));
    });
  });
}
