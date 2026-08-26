/// Data transfer objects for the sync API layer.
///
/// These DTOs are hand-written and decoupled from Drift-generated row types,
/// allowing the sync API to be tested independently of the database.
library;

import 'package:decimal/decimal.dart';

/// A pending sale ready for sync.
class PendingSaleDto {
  final String clientSaleId;
  final String status;
  final String businessLocationId;
  final List<PendingSaleLineItemDto> lineItems;
  final Decimal discountAmount;
  final String paymentMethod;
  final DateTime occurredAt;
  final int? deviceSequence;
  final String? voidOrRefundReason;

  PendingSaleDto({
    required this.clientSaleId,
    required this.status,
    required this.businessLocationId,
    required this.lineItems,
    required this.discountAmount,
    required this.paymentMethod,
    required this.occurredAt,
    this.deviceSequence,
    this.voidOrRefundReason,
  });

  Map<String, dynamic> toJson() => {
    'client_sale_id': clientSaleId,
    'status': status,
    'business_location_id': businessLocationId,
    'line_items': lineItems.map((li) => li.toJson()).toList(),
    'discount_amount': discountAmount.toString(),
    'payment_method': paymentMethod,
    'occurred_at': occurredAt.toIso8601String(),
    'device_sequence': deviceSequence,
    'void_or_refund_reason': voidOrRefundReason,
  };
}

/// A line item within a pending sale.
class PendingSaleLineItemDto {
  final String itemId;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal discountAmount;

  PendingSaleLineItemDto({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
  });

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'quantity': quantity.toString(),
    'unit_price': unitPrice.toString(),
    'discount_amount': discountAmount.toString(),
  };
}

/// Result of syncing one sale.
class SyncRowResult {
  final String clientSaleId;
  final String status; // 'created' | 'duplicate' | 'failed'
  final String? reason;

  SyncRowResult({
    required this.clientSaleId,
    required this.status,
    this.reason,
  });
}

/// Batch result from the sync API.
class SyncBatchResult {
  final List<SyncRowResult> results;

  SyncBatchResult({required this.results});
}
