/// Writes new customers to the outbox table for sync.
///
/// The producer side for `CustomerSyncService`, mirroring
/// `FinanceEntryWriter`. The generated UUID IS the customer's real,
/// permanent identity (see `customer_entries.dart`'s doc comment) — the
/// checkout picker needs it back immediately so a customer created
/// mid-cart can be attached to the sale being rung up, fully offline.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// Writes customers to the sync outbox table.
class CustomerEntryWriter {
  final AppDatabase _db;

  CustomerEntryWriter(this._db);

  /// Writes a new customer to the outbox and returns its (permanent) id.
  Future<String> writeCustomer({
    required String businessId,
    required String actorUserId,
    required String name,
    required String phone,
    String? email,
    String? addressLine1,
    required DateTime joinedAt,
  }) async {
    final customerId = const Uuid().v4();
    await _db.into(_db.customerEntries).insert(
      CustomerEntriesCompanion.insert(
        customerId: customerId,
        businessId: businessId,
        name: name,
        phone: phone,
        email: Value(email),
        addressLine1: Value(addressLine1),
        joinedAt: joinedAt,
        actorUserId: actorUserId,
        createdAt: DateTime.now(),
      ),
    );
    return customerId;
  }
}
