/// UI models for the purchases module (multi-line POs, GRNs, payables).
///
/// Thin wrappers over `PurchaseApiService` DTOs for the presentation layer —
/// same role `models/reorder.dart` plays over `ReorderDto`. Status strings
/// come straight from the backend enum (`draft`, `submitted`, `approved`,
/// `partially_received`, `received`, `cancelled`).
library;

import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';
import '../services/purchase_api_service.dart';

enum PurchaseOrderStatus {
  draft,
  submitted,
  approved,
  partiallyReceived,
  received,
  cancelled,
  unknown;

  static PurchaseOrderStatus fromBackend(String value) => switch (value) {
        'draft' => draft,
        'submitted' => submitted,
        'approved' => approved,
        'partially_received' => partiallyReceived,
        'received' => received,
        'cancelled' => cancelled,
        _ => unknown,
      };

  String get label => switch (this) {
        draft => L10n.t('poStatusDraft', 'Draft'),
        submitted => L10n.t('poStatusSubmitted', 'Submitted'),
        approved => L10n.t('poStatusApproved', 'Approved'),
        partiallyReceived => L10n.t('poStatusPartial', 'Partially received'),
        received => L10n.t('poStatusReceived', 'Received'),
        cancelled => L10n.t('poStatusCancelled', 'Cancelled'),
        unknown => L10n.t('unknown', 'Unknown'),
      };

  /// Still changeable — not yet fully received or cancelled.
  bool get isOpen => switch (this) {
        draft || submitted || approved || partiallyReceived => true,
        received || cancelled || unknown => false,
      };
}

/// One item line of a purchase order.
@immutable
class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.itemId,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unit,
    required this.unitCost,
  });

  factory PurchaseOrderLine.fromDto(PurchaseOrderLineDto dto) =>
      PurchaseOrderLine(
        id: dto.id,
        itemId: dto.itemId,
        quantityOrdered: dto.quantityOrdered.toDouble(),
        quantityReceived: dto.quantityReceived.toDouble(),
        unit: dto.unit,
        unitCost: dto.unitCost.toDouble(),
      );

  final String id;
  final String itemId;
  final double quantityOrdered;
  final double quantityReceived;
  final String unit;
  final double unitCost;

  double get outstanding => quantityOrdered - quantityReceived;
  double get lineTotal => quantityOrdered * unitCost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrderLine && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// A multi-line purchase order header with its lines.
@immutable
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.storeId,
    required this.supplierId,
    required this.poNumber,
    required this.status,
    required this.invoiceStatus,
    required this.totalAmount,
    required this.orderedAt,
    this.expectedAt,
    this.receivedAt,
    this.notes,
    this.lines = const [],
    this.invoices = const [],
  });

  factory PurchaseOrder.fromDto(PurchaseOrderDto dto) => PurchaseOrder(
        id: dto.id,
        storeId: dto.storeId,
        supplierId: dto.supplierId,
        poNumber: dto.poNumber,
        status: PurchaseOrderStatus.fromBackend(dto.status),
        invoiceStatus: dto.invoiceStatus,
        totalAmount: dto.totalAmount.toDouble(),
        orderedAt: dto.orderedAt,
        expectedAt: dto.expectedAt,
        receivedAt: dto.receivedAt,
        notes: dto.notes,
        lines: dto.lines.map(PurchaseOrderLine.fromDto).toList(),
        invoices: dto.invoices,
      );

  final String id;
  final String storeId;
  final String supplierId;
  final String poNumber;
  final PurchaseOrderStatus status;
  final String invoiceStatus;
  final double totalAmount;
  final DateTime orderedAt;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final String? notes;
  final List<PurchaseOrderLine> lines;
  final List<SupplierInvoiceDto> invoices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrder && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
