/// Write-side API client for Inventory Service — the purchases module.
///
/// Matches `ReorderApiService`'s convention: a plain Dio-wrapping class,
/// no offline/demo mode — every call here requires connectivity. Purchases
/// are strictly online-only: there is no Drift outbox or background sync
/// for POs, GRNs, returns, invoices, or payments (unlike POS sales or
/// finance). The UI gates these calls on `isOnlineProvider` and surfaces
/// `PurchaseApiException.message` directly.
library;

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../constants/api_paths.dart';

/// Thrown when the backend rejects a purchase write — a sellable-item
/// rejection, an over-receive conflict, an overpay, etc. Callers can show
/// [message] directly.
class PurchaseApiException implements Exception {
  final String message;
  final int? statusCode;

  PurchaseApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'PurchaseApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

// ── DTOs ─────────────────────────────────────────────────────────────────

Decimal _dec(dynamic v) => Decimal.parse(v.toString());
DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

class PurchaseOrderLineInput {
  final String itemId;
  final Decimal quantityOrdered;
  final Decimal unitCost;
  final String? notes;

  const PurchaseOrderLineInput({
    required this.itemId,
    required this.quantityOrdered,
    required this.unitCost,
    this.notes,
  });
}

class PurchaseOrderLineDto {
  final String id;
  final String purchaseOrderId;
  final String itemId;
  final Decimal quantityOrdered;
  final Decimal quantityReceived;
  final String unit;
  final Decimal unitCost;
  final String? notes;

  const PurchaseOrderLineDto({
    required this.id,
    required this.purchaseOrderId,
    required this.itemId,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unit,
    required this.unitCost,
    this.notes,
  });

  factory PurchaseOrderLineDto.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderLineDto(
        id: j['id'] as String,
        purchaseOrderId: j['purchase_order_id'] as String,
        itemId: j['item_id'] as String,
        quantityOrdered: _dec(j['quantity_ordered']),
        quantityReceived: _dec(j['quantity_received']),
        unit: j['unit'] as String,
        unitCost: _dec(j['unit_cost']),
        notes: j['notes'] as String?,
      );

  Decimal get outstanding => quantityOrdered - quantityReceived;
}

class PurchaseOrderDto {
  final String id;
  final String businessId;
  final String storeId;
  final String supplierId;
  final String poNumber;
  final String status;
  final String invoiceStatus;
  final Decimal totalAmount;
  final String? notes;
  final DateTime orderedAt;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final List<PurchaseOrderLineDto> lines;
  final List<SupplierInvoiceDto> invoices;

  const PurchaseOrderDto({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.supplierId,
    required this.poNumber,
    required this.status,
    required this.invoiceStatus,
    required this.totalAmount,
    this.notes,
    required this.orderedAt,
    this.expectedAt,
    this.receivedAt,
    this.lines = const [],
    this.invoices = const [],
  });

  factory PurchaseOrderDto.fromJson(Map<String, dynamic> j) => PurchaseOrderDto(
        id: j['id'] as String,
        businessId: j['business_id'] as String,
        storeId: j['store_id'] as String,
        supplierId: j['supplier_id'] as String,
        poNumber: j['po_number'] as String,
        status: j['status'] as String,
        invoiceStatus: j['invoice_status'] as String,
        totalAmount: _dec(j['total_amount']),
        notes: j['notes'] as String?,
        orderedAt: DateTime.parse(j['ordered_at'] as String),
        expectedAt: _dt(j['expected_at']),
        receivedAt: _dt(j['received_at']),
        lines: switch (j['lines']) {
          final List lines => lines
              .map((e) => PurchaseOrderLineDto.fromJson(e as Map<String, dynamic>))
              .toList(),
          _ => const [],
        },
        invoices: switch (j['invoices']) {
          final List invoices => invoices
              .map((e) => SupplierInvoiceDto.fromJson(e as Map<String, dynamic>))
              .toList(),
          _ => const [],
        },
      );
}

class GoodsReceiptLineInput {
  final String purchaseOrderLineId;
  final Decimal quantityReceived;

  const GoodsReceiptLineInput({
    required this.purchaseOrderLineId,
    required this.quantityReceived,
  });
}

class GoodsReceiptDto {
  final String id;
  final String purchaseOrderId;
  final String grnNumber;
  final DateTime receivedAt;
  final List<PurchaseOrderLineDto> lines;

  const GoodsReceiptDto({
    required this.id,
    required this.purchaseOrderId,
    required this.grnNumber,
    required this.receivedAt,
    this.lines = const [],
  });

  factory GoodsReceiptDto.fromJson(Map<String, dynamic> j) => GoodsReceiptDto(
        id: j['id'] as String,
        purchaseOrderId: j['purchase_order_id'] as String,
        grnNumber: j['grn_number'] as String,
        receivedAt: DateTime.parse(j['received_at'] as String),
        lines: switch (j['lines']) {
          final List lines => lines
              .map((e) => PurchaseOrderLineDto.fromJson(e as Map<String, dynamic>))
              .toList(),
          _ => const [],
        },
      );
}

class SupplierInvoiceDto {
  final String id;
  final String supplierId;
  final String purchaseOrderId;
  final String invoiceNumber;
  final Decimal amountTotal;
  final Decimal amountPaid;
  final String status;

  const SupplierInvoiceDto({
    required this.id,
    required this.supplierId,
    required this.purchaseOrderId,
    required this.invoiceNumber,
    required this.amountTotal,
    required this.amountPaid,
    required this.status,
  });

  factory SupplierInvoiceDto.fromJson(Map<String, dynamic> j) =>
      SupplierInvoiceDto(
        id: j['id'] as String,
        supplierId: j['supplier_id'] as String,
        purchaseOrderId: j['purchase_order_id'] as String,
        invoiceNumber: j['invoice_number'] as String,
        amountTotal: _dec(j['amount_total']),
        amountPaid: _dec(j['amount_paid']),
        status: j['status'] as String,
      );

  Decimal get remaining => amountTotal - amountPaid;
}

// ── Service ──────────────────────────────────────────────────────────────

class PurchaseApiService {
  const PurchaseApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Never _rethrow(DioException e) {
    final detail = e.response?.data is Map ? (e.response?.data as Map)['detail'] : null;
    throw PurchaseApiException(
      detail?.toString() ?? e.message ?? 'Request failed',
      e.response?.statusCode,
    );
  }

  /// Lists purchase orders. Requires `procurement.view`.
  Future<List<PurchaseOrderDto>> fetchOrders({
    required String businessId,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        InventoryApiPaths.purchaseOrders(businessId),
        queryParameters: {if (status != null) 'status': status},
      );
      final items = (response.data as Map<String, dynamic>)['items'] as List;
      return items
          .map((e) => PurchaseOrderDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Fetches one order with lines, receipts, and invoices.
  /// Requires `procurement.view`.
  Future<PurchaseOrderDto> fetchOrder({
    required String businessId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.get(
        InventoryApiPaths.purchaseOrder(businessId, orderId),
      );
      return PurchaseOrderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Drafts a multi-line purchase order. Requires `procurement.create`.
  Future<PurchaseOrderDto> createOrder({
    required String businessId,
    required String storeId,
    required String supplierId,
    required List<PurchaseOrderLineInput> lines,
    String? poNumber,
    String? notes,
    DateTime? expectedAt,
  }) async {
    try {
      final response = await _dio.post(
        InventoryApiPaths.purchaseOrders(businessId),
        data: {
          'store_id': storeId,
          'supplier_id': supplierId,
          if (poNumber != null) 'po_number': poNumber,
          if (notes != null) 'notes': notes,
          if (expectedAt != null) 'expected_at': expectedAt.toIso8601String(),
          'lines': [
            for (final line in lines)
              {
                'item_id': line.itemId,
                'quantity_ordered': line.quantityOrdered.toString(),
                'unit_cost': line.unitCost.toString(),
                if (line.notes != null) 'notes': line.notes,
              },
          ],
        },
      );
      return PurchaseOrderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  Future<PurchaseOrderDto> _orderAction({
    required String businessId,
    required String orderId,
    required String action,
  }) async {
    try {
      final response = await _dio.post(
        InventoryApiPaths.purchaseOrderAction(businessId, orderId, action),
      );
      return PurchaseOrderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Submits a draft order. Requires `procurement.create`.
  Future<PurchaseOrderDto> submitOrder({
    required String businessId,
    required String orderId,
  }) =>
      _orderAction(businessId: businessId, orderId: orderId, action: 'submit');

  /// Approves a submitted order. Requires `procurement.approve`.
  Future<PurchaseOrderDto> approveOrder({
    required String businessId,
    required String orderId,
  }) =>
      _orderAction(businessId: businessId, orderId: orderId, action: 'approve');

  /// Cancels a draft/submitted/approved order. Requires `procurement.create`.
  Future<PurchaseOrderDto> cancelOrder({
    required String businessId,
    required String orderId,
  }) =>
      _orderAction(businessId: businessId, orderId: orderId, action: 'cancel');

  /// Records a goods receipt (partial or full) against an approved order —
  /// adds quantities to stock via the backend's stock-movement engine.
  /// Requires `procurement.receive`.
  Future<GoodsReceiptDto> receiveOrder({
    required String businessId,
    required String orderId,
    required List<GoodsReceiptLineInput> lines,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        InventoryApiPaths.purchaseOrderAction(businessId, orderId, 'receive'),
        data: {
          if (notes != null) 'notes': notes,
          'lines': [
            for (final line in lines)
              {
                'purchase_order_line_id': line.purchaseOrderLineId,
                'quantity_received': line.quantityReceived.toString(),
              },
          ],
        },
      );
      return GoodsReceiptDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Returns stock to a supplier. Requires `procurement.receive`.
  Future<Map<String, dynamic>> createReturn({
    required String businessId,
    required String itemId,
    required Decimal quantity,
    String? purchaseOrderId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        InventoryApiPaths.purchaseReturns(businessId),
        data: {
          'item_id': itemId,
          'quantity': quantity.toString(),
          if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
          if (reason != null) 'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Captures the supplier's bill for an order. Requires `procurement.approve`.
  Future<SupplierInvoiceDto> createInvoice({
    required String businessId,
    required String purchaseOrderId,
    required String invoiceNumber,
    Decimal? amountTotal,
  }) async {
    try {
      final response = await _dio.post(
        InventoryApiPaths.purchaseInvoices(businessId),
        data: {
          'purchase_order_id': purchaseOrderId,
          'invoice_number': invoiceNumber,
          if (amountTotal != null) 'amount_total': amountTotal.toString(),
        },
      );
      return SupplierInvoiceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Records one payment against an invoice. Requires `procurement.approve`.
  Future<Map<String, dynamic>> recordPayment({
    required String businessId,
    required String invoiceId,
    required Decimal amount,
    String? method,
    String? reference,
  }) async {
    try {
      final response = await _dio.post(
        InventoryApiPaths.purchaseInvoicePayments(businessId, invoiceId),
        data: {
          'amount': amount.toString(),
          if (method != null) 'method': method,
          if (reference != null) 'reference': reference,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _rethrow(e);
    }
  }
}
