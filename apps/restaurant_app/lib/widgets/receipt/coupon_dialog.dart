import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/order.dart';
import '../../printing/thermal_coupon.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'thermal_receipt_preview.dart';

/// Paper preview of the claim coupon with fake data, mirroring the receipt's
/// sample preview in Store Settings.
Future<void> showSampleCouponPreviewDialog(
  BuildContext context,
  WidgetRef ref,
) {
  final sample = Order(
    id: 'ORD-0042',
    placedAt: DateTime(2026, 8, 6, 14, 15),
    paymentType: PaymentType.cash,
    status: OrderStatus.paid,
    taxRate: 0,
    orderType: OrderType.dineIn,
    tableLabel: 'Table 12',
    serverName: 'Ava',
    lines: [
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
  return showCouponPreviewDialog(context, ref, sample);
}

/// Paper preview of the claim coupon for [order]: store proof, the order
/// number at double size, and the items — nothing else.
Future<void> showCouponPreviewDialog(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  final profile = ref.read(businessProfileProvider);

  final lines = buildThermalCoupon(
    order: order,
    storeName: profile?.name ?? ref.read(storeNameProvider),
    phone: profile?.phone,
    addressLines: [
      if (profile != null && profile.hasAddress)
        ...profile.formattedAddress.split('\n'),
    ],
  );

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.couponPreviewTitle),
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
              SnackBar(content: Text(AppStrings.couponSent(order.id))),
            );
          },
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(AppStrings.receiptPrintAction),
        ),
      ],
    ),
  );
}
