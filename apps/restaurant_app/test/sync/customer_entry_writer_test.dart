/// Tests for `CustomerEntryWriter` — the bridge from a saved customer form
/// (including one created mid-checkout) onto the `CustomerEntries` outbox.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/sync/customer_entry_writer.dart';

void main() {
  group('CustomerEntryWriter', () {
    late AppDatabase database;
    late CustomerEntryWriter writer;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      writer = CustomerEntryWriter(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('writeCustomer inserts a pending outbox row with a UUID id', () async {
      final customerId = await writer.writeCustomer(
        businessId: 'biz-1',
        actorUserId: 'staff-1',
        name: 'Jane Doe',
        phone: '+1-555-0100',
        email: 'jane@example.com',
        joinedAt: DateTime(2026, 1, 1),
      );

      expect(customerId, isNotEmpty);
      expect(customerId.length, 36); // UUID v4 canonical length

      final rows = await database.select(database.customerEntries).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.customerId, customerId);
      expect(row.businessId, 'biz-1');
      expect(row.name, 'Jane Doe');
      expect(row.phone, '+1-555-0100');
      expect(row.email, 'jane@example.com');
      expect(row.actorUserId, 'staff-1');
      expect(row.syncStatus, 'pending');
    });

    test('each write gets a distinct id', () async {
      final id1 = await writer.writeCustomer(
        businessId: 'b1',
        actorUserId: 'u1',
        name: 'a',
        phone: '1',
        joinedAt: DateTime.now(),
      );
      final id2 = await writer.writeCustomer(
        businessId: 'b1',
        actorUserId: 'u1',
        name: 'b',
        phone: '2',
        joinedAt: DateTime.now(),
      );
      expect(id1, isNot(equals(id2)));
    });

    test('the returned id is immediately usable — it is the row primary key', () async {
      // Simulates the checkout picker: a customer created mid-cart must be
      // attachable to a sale in the very same offline session.
      final customerId = await writer.writeCustomer(
        businessId: 'biz-1',
        actorUserId: 'staff-1',
        name: 'Walk-in Add',
        phone: '+1-555-0199',
        joinedAt: DateTime.now(),
      );

      final row = await (database.select(database.customerEntries)
            ..where((r) => r.customerId.equals(customerId)))
          .getSingle();
      expect(row.customerId, customerId);
    });
  });
}
