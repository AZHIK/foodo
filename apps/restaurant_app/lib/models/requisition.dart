/// UI models for the requisition flow: ONE unified cart, split per supplier.
///
/// [RequisitionCartLine] is session-only state (never a server row until
/// submit — see the cart provider). The DTOs mirror the backend's
/// `app/schemas/requisitions.py` for the submit response.
library;

import 'package:flutter/foundation.dart';

/// One line in the session cart. `supplierId` is written by BOTH the
/// per-item picker and the bulk-assign action — same field, bulk is only a
/// convenience layer. `assignmentSource` records which path wrote it last
/// (`manual_per_item` | `bulk_all`), purely informational for the UI.
@immutable
class RequisitionCartLine {
  const RequisitionCartLine({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.qty,
    this.supplierId,
    this.supplierName,
    this.priceUnconfirmed = false,
    this.assignmentSource,
  });

  final String itemId;
  final String itemName;
  final String unit;
  final double qty;
  final String? supplierId;
  final String? supplierName;
  final bool priceUnconfirmed;
  final String? assignmentSource;

  bool get hasSupplier => supplierId != null;

  RequisitionCartLine copyWith({
    double? qty,
    String? supplierId,
    String? supplierName,
    bool? priceUnconfirmed,
    String? assignmentSource,
    bool clearSupplier = false,
  }) {
    return RequisitionCartLine(
      itemId: itemId,
      itemName: itemName,
      unit: unit,
      qty: qty ?? this.qty,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      priceUnconfirmed: priceUnconfirmed ?? this.priceUnconfirmed,
      assignmentSource: clearSupplier
          ? null
          : (assignmentSource ?? this.assignmentSource),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RequisitionCartLine &&
          other.itemId == itemId &&
          other.supplierId == supplierId);

  @override
  int get hashCode => Object.hash(itemId, supplierId);
}

/// One supplier group of the submitted order (Option 2 UX: no PO numbers
/// here — those live in the export view only).
@immutable
class RequisitionSupplierGroup {
  const RequisitionSupplierGroup({
    required this.poId,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.subtotal,
    required this.lines,
    this.deepLink,
    this.textPreview,
    this.hasWhatsapp = true,
  });

  final String poId;

  /// Real PO number — rendered ONLY in the export/reconciliation view, never
  /// in the primary order screen (Option 2 UX).
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final String status;
  final double subtotal;
  final List<RequisitionGroupLine> lines;
  final String? deepLink;
  final String? textPreview;
  final bool hasWhatsapp;

  /// Backend lifecycle mapped to the staff-facing badge.
  String get badge {
    return switch (status) {
      'sent' => 'Sent',
      'confirmed' || 'fulfilled' || 'received' => 'Confirmed',
      'partially_fulfilled' || 'partially_received' => 'Partial',
      'cancelled' => 'Cancelled',
      _ => 'Not sent',
    };
  }

  bool get isTerminal =>
      status == 'confirmed' ||
      status == 'fulfilled' ||
      status == 'received' ||
      status == 'cancelled';
}

@immutable
class RequisitionGroupLine {
  const RequisitionGroupLine({
    required this.name,
    required this.qty,
    required this.unit,
    this.unitPrice,
    this.lineTotal,
    this.priceUnconfirmed = false,
  });

  final String name;
  final String qty;
  final String unit;
  final String? unitPrice;
  final String? lineTotal;
  final bool priceUnconfirmed;
}

/// Submitted requisition: header + per-supplier groups + rollup.
@immutable
class SubmittedRequisition {
  const SubmittedRequisition({
    required this.id,
    required this.rollupStatus,
    required this.groups,
    this.priceUnconfirmedItems = const [],
    this.orderedAt,
    this.expectedAt,
  });

  final String id;
  final String rollupStatus;
  final List<RequisitionSupplierGroup> groups;
  final List<String> priceUnconfirmedItems;
  final DateTime? orderedAt;
  final DateTime? expectedAt;

  double get total =>
      groups.fold(0, (sum, g) => sum + g.subtotal);

  factory SubmittedRequisition.fromJson(
    Map<String, dynamic> json,
    Map<String, String> supplierNames,
  ) {
    final pos = (json['purchase_orders'] as List?) ?? const [];
    final messages = (json['messages'] as List?) ?? const [];
    final payloadByPo = <String, Map<String, dynamic>>{};
    for (final m in messages) {
      final map = m as Map<String, dynamic>;
      final payload = map['payload'] as Map<String, dynamic>?;
      if (payload != null) payloadByPo[map['po_id'] as String] = payload;
    }
    final req = json['requisition'] as Map<String, dynamic>;
    return SubmittedRequisition(
      id: req['id'] as String,
      rollupStatus: json['rollup_status'] as String? ?? 'Not sent',
      priceUnconfirmedItems:
          ((json['price_unconfirmed_items'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
      orderedAt: req['created_at'] == null
          ? null
          : DateTime.tryParse(req['created_at'] as String),
      expectedAt: req['expected_at'] == null
          ? null
          : DateTime.tryParse(req['expected_at'] as String),
      groups: [
        for (final po in pos)
          _groupFromPo(
            po as Map<String, dynamic>,
            supplierNames,
            payloadByPo[po['id'] as String],
          ),
      ],
    );
  }

  static RequisitionSupplierGroup _groupFromPo(
    Map<String, dynamic> po,
    Map<String, String> supplierNames,
    Map<String, dynamic>? payload,
  ) {
    final supplierId = po['supplier_id'] as String;
    final structured =
        payload?['structured_data'] as Map<String, dynamic>?;
    final items = (structured?['items'] as List?) ?? const [];
    return RequisitionSupplierGroup(
      poId: po['id'] as String,
      poNumber: po['po_number'] as String? ?? '',
      supplierId: supplierId,
      supplierName: supplierNames[supplierId] ?? 'Supplier',
      status: po['status'] as String? ?? 'payload_ready',
      subtotal: double.tryParse(po['total_amount'].toString()) ?? 0,
      lines: [
        for (final e in items)
          RequisitionGroupLine(
            name: (e as Map)['name'].toString(),
            qty: e['qty'].toString(),
            unit: (e['unit'] ?? '').toString(),
            unitPrice: e['unit_price']?.toString(),
            lineTotal: e['line_total']?.toString(),
            priceUnconfirmed: e['price_unconfirmed'] == true,
          ),
      ],
      deepLink: payload?['deep_link'] as String?,
      textPreview: payload?['text_preview'] as String?,
      hasWhatsapp: payload != null,
    );
  }
}
