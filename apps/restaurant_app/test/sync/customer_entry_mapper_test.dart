/// Tests for the customer read-side mapper: cached-row and outbox-row ->
/// `Customer` mapping.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/database/app_database.dart';
import 'package:restaurant_pos/sync/customer_entry_mapper.dart';

void main() {
  group('customerFromCachedRow', () {
    test('maps a synced cached customer row, including aggregates', () {
      final row = CachedCustomer(
        id: 'cust-1',
        businessId: 'biz-1',
        name: 'Jane Doe',
        phone: '+1-555-0100',
        email: 'jane@example.com',
        addressLine1: null,
        actorId: 'staff-1',
        joinedAt: DateTime(2026, 1, 1),
        syncedAt: DateTime(2026, 1, 1, 1),
        updatedAt: DateTime(2026, 1, 1, 1),
        isDeleted: false,
        createdAt: DateTime(2026, 1, 1),
        totalOrders: 3,
        totalSpent: Decimal.parse('450.00'),
        lastOrderAt: DateTime(2026, 2, 1),
        lastSyncedAt: DateTime(2026, 2, 2),
      );

      final customer = customerFromCachedRow(row);

      expect(customer.id, 'cust-1');
      expect(customer.serverId, 'cust-1');
      expect(customer.name, 'Jane Doe');
      expect(customer.phone, '+1-555-0100');
      expect(customer.email, 'jane@example.com');
      expect(customer.totalOrders, 3);
      expect(customer.totalSpent, 450.00);
      expect(customer.lastOrderAt, DateTime(2026, 2, 1));
      expect(customer.syncStatus, 'synced');
    });
  });

  group('customerFromOutboxRow', () {
    test('a pending row has zeroed aggregates and no serverId', () {
      final row = CustomerEntry(
        id: 1,
        customerId: 'cust-1',
        businessId: 'biz-1',
        name: 'Jane Doe',
        phone: '+1-555-0100',
        email: null,
        addressLine1: null,
        joinedAt: DateTime(2026, 1, 1),
        actorUserId: 'staff-1',
        syncStatus: 'pending',
        syncError: null,
        syncAttemptCount: 0,
        lastAttemptAt: null,
        syncedAt: null,
        createdAt: DateTime(2026, 1, 1),
      );

      final customer = customerFromOutboxRow(row);

      expect(customer.id, 'cust-1');
      expect(customer.serverId, isNull);
      expect(customer.syncStatus, 'pending');
      expect(customer.totalOrders, 0);
      expect(customer.totalSpent, 0);
      expect(customer.lastOrderAt, isNull);
    });

    test('a synced outbox row (not yet pulled back into cache) has serverId set', () {
      final row = CustomerEntry(
        id: 1,
        customerId: 'cust-1',
        businessId: 'biz-1',
        name: 'Jane Doe',
        phone: '+1-555-0100',
        email: null,
        addressLine1: null,
        joinedAt: DateTime(2026, 1, 1),
        actorUserId: 'staff-1',
        syncStatus: 'synced',
        syncError: null,
        syncAttemptCount: 1,
        lastAttemptAt: DateTime(2026, 1, 1),
        syncedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );

      final customer = customerFromOutboxRow(row);
      expect(customer.serverId, 'cust-1');
    });
  });
}
