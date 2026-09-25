import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/order.dart';
import '../../printing/thermal_receipt.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'thermal_receipt_preview.dart';

/// Paper preview of the standard thermal receipt with fake data, so the owner
/// can approve the 80mm format from Store Settings without a real sale.
///
/// The store header is real (this store's identity); only the order is
/// sample data, exercising every block: discount, tax, cash change, table.
Future<void> showSampleReceiptPreviewDialog(
  BuildContext context,
  WidgetRef ref,
) {
  final sample = Order(
    id: 'ORD-0042',
    placedAt: DateTime.now(),
    paymentType: PaymentType.cash,
    status: OrderStatus.paid,
    taxRate: ref.read(taxRateProvider),
    orderType: OrderType.dineIn,
    discountRate: 0.10,
    tableLabel: 'Table 12',
    serverName: 'Ava',
    amountTendered: 15000,
    lines: const [
      OrderLine(
        itemId: 'sample-1',
        name: 'Pilau Beef',
        emoji: '🍚',
        unitPrice: 4800,
        quantity: 2,
      ),
      OrderLine(
        itemId: 'sample-2',
        name: 'Chips Mayai',
        emoji: '🍟',
        unitPrice: 4000,
        quantity: 1,
      ),
    ],
  );
  return showReceiptPreviewDialog(context, ref, sample);
}

/// Paper preview of the standard thermal receipt for [order].
///
/// Reads the store identity (name, contacts, tax id) and the receipt-number
/// prefix from their providers — the same sources a future printer encoder
/// will read, so an approved preview agrees with the paper.
Future<void> showReceiptPreviewDialog(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  final profile = ref.read(businessProfileProvider);
  final receiptNumber =
      '${ref.read(receiptPrefixProvider)}${order.receiptSuffix}';

  final lines = buildThermalReceipt(
    order: order,
    storeName: profile?.name ?? ref.read(storeNameProvider),
    receiptNumber: receiptNumber,
    phone: profile?.phone,
    email: profile?.email,
    addressLines: [
      if (profile != null && profile.hasAddress)
        ...profile.formattedAddress.split('\n'),
    ],
    taxId: profile?.taxId,
    welcomeNote: AppStrings.receiptWelcomeNote,
  );

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.receiptPreviewTitle),
          Text(
            AppStrings.receiptPreviewSubtitle,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: ThermalReceiptPreview.paperWidth,
        child: SingleChildScrollView(
          child: ThermalReceiptPreview(lines: lines),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.receiptSentWithNumber(
                    ref.read(receiptPrefixProvider),
                    order.receiptSuffix,
                  ),
                ),
              ),
            );
          },
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(AppStrings.receiptPrintAction),
        ),
      ],
    ),
  );
}
