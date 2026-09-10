/// Maps POS Service's cached/outbox customer rows onto the UI's `Customer`
/// model.
///
/// The read-side counterpart to `customer_entry_writer.dart`, mirroring
/// `finance_entry_mapper.dart`'s shape.
library;

import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../models/customer.dart';

double _toDouble(Decimal value) => double.parse(value.toString());

/// Maps a pulled, already-synced customer row to the UI model.
Customer customerFromCachedRow(CachedCustomer row) => Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      addressLine1: row.addressLine1,
      createdAt: row.joinedAt,
      lastOrderAt: row.lastOrderAt,
      totalOrders: row.totalOrders,
      totalSpent: _toDouble(row.totalSpent),
      serverId: row.id,
      syncStatus: 'synced',
    );

/// Maps a not-yet-(fully-)synced outbox row to the UI model, so a
/// locally-created customer is visible immediately and survives a restart
/// before its background sync completes. Order aggregates are always zero
/// here — they only exist once the backend has computed them.
Customer customerFromOutboxRow(CustomerEntry row) => Customer(
      id: row.customerId,
      name: row.name,
      phone: row.phone,
      email: row.email,
      addressLine1: row.addressLine1,
      createdAt: row.joinedAt,
      lastOrderAt: null,
      totalOrders: 0,
      totalSpent: 0,
      serverId: row.syncStatus == 'synced' ? row.customerId : null,
      syncStatus: row.syncStatus,
    );
