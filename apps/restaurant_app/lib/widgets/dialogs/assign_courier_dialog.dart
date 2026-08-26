import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../providers/couriers_provider.dart';
import '../../providers/orders_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../responsive_form_dialog.dart';
import '../section_label.dart';

/// Opens the courier assignment dialog for a delivery order.
Future<void> showAssignCourierDialog(
  BuildContext context,
  Order order,
) {
  return showResponsiveFormDialog<void>(
    context,
    builder: (_) => _AssignCourierDialog(order: order),
  );
}

class _AssignCourierDialog extends ConsumerWidget {
  const _AssignCourierDialog({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCouriers = ref.watch(activeCouriersProvider);
    final currentCourier = order.courierId != null
        ? ref.watch(courierByIdProvider(order.courierId!))
        : null;

    return ResponsiveFormDialog(
      title: 'Assign courier for ${order.id}',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentCourier != null) ...[
            const SectionLabel('Currently assigned'),
            const SizedBox(height: Insets.md),
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(Insets.md),
                border: Border.all(
                  color: context.colors.primary,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentCourier.name,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    currentCourier.phone,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    currentCourier.vehicle,
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.xl),
            const SectionLabel('Reassign to'),
            const SizedBox(height: Insets.md),
          ] else ...[
            const SectionLabel('Select courier'),
            const SizedBox(height: Insets.md),
          ],
          if (activeCouriers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      size: 48,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: Insets.md),
                    Text(
                      'No couriers available',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeCouriers.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: Insets.sm),
              itemBuilder: (context, index) {
                final courier = activeCouriers[index];
                final isCurrently = order.courierId == courier.id;

                return Material(
                  color: isCurrently
                      ? context.colors.primaryContainer
                      : context.colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(Insets.md),
                  child: InkWell(
                    onTap: () {
                      ref.read(ordersProvider.notifier).setOrderCourier(
                            order.id,
                            courier.id,
                          );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${courier.name} assigned to ${order.id}',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(Insets.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCurrently
                              ? context.colors.primary
                              : context.semantic.hairline,
                        ),
                        borderRadius: BorderRadius.circular(Insets.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  courier.name,
                                  style: context.text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: Insets.xs),
                                Text(
                                  courier.phone,
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: Insets.xs),
                                Text(
                                  courier.vehicle,
                                  style: context.text.labelSmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrently)
                            Icon(
                              Icons.check_circle_rounded,
                              color: context.colors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
