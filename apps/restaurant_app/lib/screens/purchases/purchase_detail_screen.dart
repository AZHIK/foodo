import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/permission.dart';
import '../../models/purchase_order.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/suppliers_provider.dart';
import '../../services/purchase_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/formatters.dart';
import '../../widgets/data_page/status_badge.dart';

/// Detail for one purchase order: lines, status actions, GRN receiving,
/// returns, invoices, and payments.
///
/// Online-only like the list screen: without connectivity the detail shows
/// the offline placeholder (its numbers drive stock and money).
class PurchaseDetailScreen extends ConsumerStatefulWidget {
  const PurchaseDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PurchaseDetailScreen> createState() =>
      _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen> {
  PurchaseOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefer list state for instant paint; fetch full detail in background.
    final cached = ref.read(purchaseByIdProvider(widget.orderId));
    if (cached != null) {
      _order = cached;
      _loading = cached.lines.isEmpty;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final order =
          await ref.read(purchasesProvider.notifier).fetchDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _run(
    Future<void> Function() action,
    String ok,
    String Function(Object) fail,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _load();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(fail(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final order = _order;

    return Scaffold(
      appBar: AppBar(
        title: Text(order?.poNumber ?? AppStrings.purchasesTitle),
        elevation: 0,
        actions: [
          if (online && !_loading)
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: !online
          ? _offline()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && order == null
                  ? _failure(_error!)
                  : _DetailBody(
                      order: order!,
                      onAction: _run,
                      onChanged: _load,
                    ),
    );
  }

  Widget _offline() {
    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        const SizedBox(height: Insets.xl * 2),
        Icon(Icons.cloud_off_outlined,
            size: 48, color: context.colors.onSurfaceVariant),
        const SizedBox(height: Insets.md),
        Text(AppStrings.purchasesOfflineTitle,
            style: context.text.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: Insets.sm),
        Text(
          AppStrings.purchasesOfflineBody,
          style: context.text.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _failure(String message) {
    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        const SizedBox(height: Insets.xl * 2),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: Insets.lg),
        Center(
          child: FilledButton.tonal(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
            child: Text(AppStrings.retryAction),
          ),
        ),
      ],
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.order,
    required this.onAction,
    required this.onChanged,
  });

  final PurchaseOrder order;
  final Future<void> Function(
    Future<void> Function(),
    String,
    String Function(Object),
  ) onAction;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplier = ref.watch(supplierByIdProvider(order.supplierId));
    final canCreate =
        ref.watch(hasPermissionProvider(AppPermissions.procurementCreate));
    final canApprove =
        ref.watch(hasPermissionProvider(AppPermissions.procurementApprove));
    final canReceive =
        ref.watch(hasPermissionProvider(AppPermissions.procurementReceive));
    final tone = switch (order.status) {
      PurchaseOrderStatus.draft => StatusTone.neutral,
      PurchaseOrderStatus.submitted => StatusTone.warning,
      PurchaseOrderStatus.approved => StatusTone.warning,
      PurchaseOrderStatus.partiallyReceived => StatusTone.warning,
      PurchaseOrderStatus.received => StatusTone.positive,
      PurchaseOrderStatus.cancelled => StatusTone.neutral,
      // Requisition-split lifecycle: action still needed until fulfilled.
      PurchaseOrderStatus.payloadReady => StatusTone.warning,
      PurchaseOrderStatus.sent => StatusTone.warning,
      PurchaseOrderStatus.confirmed => StatusTone.warning,
      PurchaseOrderStatus.partiallyFulfilled => StatusTone.warning,
      PurchaseOrderStatus.fulfilled => StatusTone.positive,
      PurchaseOrderStatus.unknown => StatusTone.neutral,
    };
    final notifier = ref.read(purchasesProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.poNumber, style: context.text.titleLarge),
                  const SizedBox(height: Insets.xs),
                  Text(
                    supplier?.name ?? AppStrings.unknownSupplier,
                    style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusBadge(label: order.status.label, tone: tone, dense: true),
          ],
        ),
        const SizedBox(height: Insets.sm),
        Text(
          '${Fmt.money(order.totalAmount)} · ${Fmt.relativeDateTime(order.orderedAt)}',
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        if (order.notes != null) ...[
          const SizedBox(height: Insets.sm),
          Text(
            AppStrings.notesLine(order.notes!),
            style: context.text.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Insets.md),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            if (order.status == PurchaseOrderStatus.draft && canCreate)
              FilledButton.tonal(
                onPressed: () => onAction(
                  () => notifier.submit(order.id),
                  AppStrings.orderSubmittedMessage,
                  (e) => AppStrings.transitionFailed('submit', e),
                ),
                child: Text(AppStrings.submitAction),
              ),
            if (order.status == PurchaseOrderStatus.submitted && canApprove)
              FilledButton(
                onPressed: () => onAction(
                  () => notifier.approve(order.id),
                  AppStrings.orderApprovedMessage,
                  (e) => AppStrings.transitionFailed('approve', e),
                ),
                child: Text(AppStrings.approveAction),
              ),
            if ((order.status == PurchaseOrderStatus.approved ||
                    order.status == PurchaseOrderStatus.partiallyReceived) &&
                canReceive)
              FilledButton.icon(
                onPressed: () => _showReceive(context, ref),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(AppStrings.receiveAction),
              ),
            if ((order.status == PurchaseOrderStatus.approved ||
                    order.status == PurchaseOrderStatus.partiallyReceived ||
                    order.status == PurchaseOrderStatus.received) &&
                canReceive)
              OutlinedButton(
                onPressed: () => _showReturn(context, ref),
                child: Text(AppStrings.returnAction),
              ),
            if (order.status.isOpen &&
                order.status != PurchaseOrderStatus.partiallyReceived &&
                order.status != PurchaseOrderStatus.partiallyFulfilled &&
                order.status != PurchaseOrderStatus.received &&
                canCreate)
              TextButton(
                onPressed: () => onAction(
                  () => notifier.cancel(order.id),
                  AppStrings.orderCancelledMessage,
                  (e) => AppStrings.transitionFailed('cancel', e),
                ),
                child: Text(AppStrings.cancel),
              ),
            if (canApprove &&
                (order.status == PurchaseOrderStatus.approved ||
                    order.status == PurchaseOrderStatus.partiallyReceived ||
                    order.status == PurchaseOrderStatus.received))
              OutlinedButton(
                onPressed: () => _showInvoice(context, ref),
                child: Text(AppStrings.invoiceAction),
              ),
          ],
        ),
        const SizedBox(height: Insets.xl),
        Text('Lines (${order.lines.length})', style: context.text.titleMedium),
        const SizedBox(height: Insets.md),
        ...order.lines.map((line) => _LineTile(line: line)),
        if (order.invoices.isNotEmpty) ...[
          const SizedBox(height: Insets.xl),
          Text('Invoices (${order.invoices.length})',
              style: context.text.titleMedium),
          const SizedBox(height: Insets.md),
          ...order.invoices.map((inv) => _InvoiceTile(
                invoice: inv,
                onPay: canApprove && inv.remaining > Decimal.zero
                    ? () => _showPay(context, ref, inv)
                    : null,
              )),
        ],
      ],
    );
  }

  Future<void> _showReceive(BuildContext context, WidgetRef ref) {
    return showAppDialog(
      context: context,
      builder: (_) => _ReceiveDialog(order: order, onDone: onChanged),
    );
  }

  Future<void> _showReturn(BuildContext context, WidgetRef ref) {
    return showAppDialog(
      context: context,
      builder: (_) => _ReturnDialog(order: order, onDone: onChanged),
    );
  }

  Future<void> _showInvoice(BuildContext context, WidgetRef ref) {
    return showAppDialog(
      context: context,
      builder: (_) => _InvoiceDialog(order: order, onDone: onChanged),
    );
  }

  Future<void> _showPay(
    BuildContext context,
    WidgetRef ref,
    SupplierInvoiceDto invoice,
  ) {
    return showAppDialog(
      context: context,
      builder: (_) => _PayDialog(invoice: invoice, onDone: onChanged),
    );
  }
}

class _LineTile extends ConsumerWidget {
  const _LineTile({required this.line});

  final PurchaseOrderLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryItemsListProvider);
    final item = items.where((i) => i.id == line.itemId).firstOrNull;
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        border: Border.all(color: context.semantic.hairline),
        borderRadius: BorderRadius.circular(Insets.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item?.name ?? line.itemId,
                  style: context.text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  '${Fmt.quantity(line.quantityReceived)} / ${Fmt.quantity(line.quantityOrdered)} ${line.unit} received',
                  style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.money(line.unitCost),
                  style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant)),
              Text(Fmt.money(line.lineTotal),
                  style: context.text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, this.onPay});

  final SupplierInvoiceDto invoice;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        border: Border.all(color: context.semantic.hairline),
        borderRadius: BorderRadius.circular(Insets.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNumber,
                    style: context.text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: Insets.xs),
                Text(
                  '${Fmt.money(invoice.amountPaid.toDouble())} of ${Fmt.money(invoice.amountTotal.toDouble())} paid · ${invoice.status}',
                  style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (onPay != null)
            FilledButton.tonal(onPressed: onPay, child: Text(AppStrings.payAction)),
        ],
      ),
    );
  }
}

class _ReceiveDialog extends ConsumerStatefulWidget {
  const _ReceiveDialog({required this.order, required this.onDone});

  final PurchaseOrder order;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends ConsumerState<_ReceiveDialog> {
  late final Map<String, String> _qtyByLine = {
    for (final line in widget.order.lines)
      if (line.outstanding > 0) line.id: line.outstanding.toString(),
  };
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final inputs = <GoodsReceiptLineInput>[];
    for (final line in widget.order.lines) {
      final raw = _qtyByLine[line.id];
      if (raw == null || raw.trim().isEmpty) continue;
      final qty = Decimal.tryParse(raw);
      if (qty == null || qty <= Decimal.zero) {
        setState(() => _error = 'Quantities must be positive numbers');
        return;
      }
      if (qty > Decimal.parse(line.outstanding.toString())) {
        setState(() => _error = 'Cannot receive more than outstanding');
        return;
      }
      inputs.add(GoodsReceiptLineInput(
        purchaseOrderLineId: line.id,
        quantityReceived: qty,
      ));
    }
    if (inputs.isEmpty) {
      setState(() => _error = 'Enter at least one quantity');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(purchasesProvider.notifier)
          .receive(orderId: widget.order.id, lines: inputs);
      await widget.onDone();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.goodsReceivedMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is PurchaseApiException
            ? e.message
            : AppStrings.receiveFailedGeneric(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryItemsListProvider);
    final names = {for (final i in items) i.id: i.name};
    return AlertDialog(
      title: Text(AppStrings.receiveTitle),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in widget.order.lines)
                if (line.outstanding > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText:
                            '${names[line.itemId] ?? line.itemId} (max ${Fmt.quantity(line.outstanding)} ${line.unit})',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      controller: TextEditingController(text: _qtyByLine[line.id]),
                      onChanged: (v) => _qtyByLine[line.id] = v,
                    ),
                  ),
              if (_error != null)
                Text(_error!,
                    style: TextStyle(color: context.colors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppStrings.receiveGrnAction),
        ),
      ],
    );
  }
}

class _ReturnDialog extends ConsumerStatefulWidget {
  const _ReturnDialog({required this.order, required this.onDone});

  final PurchaseOrder order;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends ConsumerState<_ReturnDialog> {
  String? _lineId;
  String _qty = '';
  String _reason = '';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final lineId = _lineId;
    final qty = Decimal.tryParse(_qty);
    if (lineId == null || qty == null || qty <= Decimal.zero) {
      setState(() => _error = 'Choose a line and a positive quantity');
      return;
    }
    final line = widget.order.lines.firstWhere((l) => l.id == lineId);
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(purchasesProvider.notifier).returnStock(
            itemId: line.itemId,
            quantity: qty,
            purchaseOrderId: widget.order.id,
            reason: _reason.isEmpty ? null : _reason,
          );
      await widget.onDone();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.returnRecordedMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            e is PurchaseApiException ? e.message : AppStrings.returnFailed(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryItemsListProvider);
    final names = {for (final i in items) i.id: i.name};
    return AlertDialog(
      title: Text(AppStrings.returnTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _lineId,
              decoration: const InputDecoration(labelText: 'Line'),
              items: [
                for (final line in widget.order.lines)
                  DropdownMenuItem(
                    value: line.id,
                    child: Text(
                      '${names[line.itemId] ?? line.itemId} — received ${Fmt.quantity(line.quantityReceived)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _lineId = v),
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _qty = v,
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
              onChanged: (v) => _reason = v,
            ),
            if (_error != null) ...[
              const SizedBox(height: Insets.sm),
              Text(_error!, style: TextStyle(color: context.colors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(AppStrings.returnAction),
        ),
      ],
    );
  }
}

class _InvoiceDialog extends ConsumerStatefulWidget {
  const _InvoiceDialog({required this.order, required this.onDone});

  final PurchaseOrder order;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends ConsumerState<_InvoiceDialog> {
  String _number = '';
  String _total = '';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_number.trim().isEmpty) {
      setState(() => _error = 'Enter the supplier invoice number');
      return;
    }
    final total =
        _total.trim().isEmpty ? null : Decimal.tryParse(_total.trim());
    if (_total.trim().isNotEmpty && total == null) {
      setState(() => _error = 'Total must be a number');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(purchasesProvider.notifier).invoice(
            orderId: widget.order.id,
            invoiceNumber: _number.trim(),
            amountTotal: total,
          );
      await widget.onDone();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoiceSavedMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            e is PurchaseApiException ? e.message : AppStrings.invoiceFailed(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.invoiceTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Supplier invoice number'),
              onChanged: (v) => _number = v,
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Total (blank = received value)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _total = v,
            ),
            if (_error != null) ...[
              const SizedBox(height: Insets.sm),
              Text(_error!, style: TextStyle(color: context.colors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(AppStrings.invoiceAction),
        ),
      ],
    );
  }
}

class _PayDialog extends ConsumerStatefulWidget {
  const _PayDialog({required this.invoice, required this.onDone});

  final SupplierInvoiceDto invoice;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends ConsumerState<_PayDialog> {
  String _amount = '';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final amount = Decimal.tryParse(_amount);
    if (amount == null || amount <= Decimal.zero) {
      setState(() => _error = 'Enter a positive amount');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(purchasesProvider.notifier).pay(
            invoiceId: widget.invoice.id,
            amount: amount,
          );
      await widget.onDone();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.paymentSavedMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            e is PurchaseApiException ? e.message : AppStrings.paymentFailed(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.payTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remaining: ${Fmt.money(widget.invoice.remaining.toDouble())}',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _amount = v,
            ),
            if (_error != null) ...[
              const SizedBox(height: Insets.sm),
              Text(_error!, style: TextStyle(color: context.colors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(AppStrings.payAction),
        ),
      ],
    );
  }
}
