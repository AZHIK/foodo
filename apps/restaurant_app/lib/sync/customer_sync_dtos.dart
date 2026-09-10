/// Data transfer objects for the customer sync API layer (push side).
///
/// Mirrors `finance_sync_dtos.dart`'s shape, with one divergence: there is
/// no separate client-id field — `CustomerDto.id` IS the customer's real
/// identity, generated on-device (see `customer_entries.dart`'s doc
/// comment).
library;

/// A pending customer ready for sync.
class CustomerDto {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? addressLine1;
  final DateTime joinedAt;
  final int? deviceSequence;

  CustomerDto({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.addressLine1,
    required this.joinedAt,
    this.deviceSequence,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'address_line1': addressLine1,
    // See `PendingSaleDto.toJson`'s comment: `.toUtc()` first is what
    // actually makes this UTC on the wire.
    'joined_at': joinedAt.toUtc().toIso8601String(),
    'device_sequence': deviceSequence,
  };
}

/// Result of syncing one customer.
class CustomerSyncRowResult {
  final String clientCustomerId;
  final String status; // 'created' | 'duplicate' | 'failed'
  final String? reason;

  CustomerSyncRowResult({
    required this.clientCustomerId,
    required this.status,
    this.reason,
  });
}

/// Batch result from the customer sync API.
class CustomerSyncBatchResult {
  final List<CustomerSyncRowResult> results;

  CustomerSyncBatchResult({required this.results});
}
