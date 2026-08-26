import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/courier.dart';
import '../../providers/couriers_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/data_page/summary_metric_card.dart';

class CouriersScreen extends ConsumerWidget {
  const CouriersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couriers = ref.watch(couriersProvider);
    final active = couriers.where((c) => c.status == CourierStatus.active).toList();
    final inactive = couriers.where((c) => c.status == CourierStatus.inactive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Couriers'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Row(
            children: [
              Expanded(child: SummaryMetricCard(label: 'Available', value: '${active.length}', trend: 'Ready for delivery', icon: Icons.two_wheeler_rounded, accent: context.semantic.success)),
              const SizedBox(width: Insets.md),
              Expanded(child: SummaryMetricCard(label: 'Unavailable', value: '${inactive.length}', trend: 'Offline', icon: Icons.block_outlined, accent: context.semantic.warning)),
              const SizedBox(width: Insets.md),
              Expanded(child: SummaryMetricCard(label: 'Total', value: '${couriers.length}', trend: 'Couriers on team', icon: Icons.groups_outlined)),
            ],
          ),
          const SizedBox(height: Insets.xl),
          if (active.isNotEmpty) ...[
            Text('Active (${active.length})', style: context.text.titleMedium),
            const SizedBox(height: Insets.md),
            ...active.map((c) => _CourierTile(courier: c)),
            const SizedBox(height: Insets.xl),
          ],
          if (inactive.isNotEmpty) ...[
            Text('Inactive (${inactive.length})', style: context.text.titleMedium),
            const SizedBox(height: Insets.md),
            ...inactive.map((c) => _CourierTile(courier: c)),
          ],
          if (couriers.isEmpty) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: Insets.xl), child: Column(children: [Icon(Icons.two_wheeler_rounded, size: 48, color: context.colors.onSurfaceVariant), const SizedBox(height: Insets.md), Text('No couriers added', style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))]))),
        ],
      ),
    );
  }
}

class _CourierTile extends StatelessWidget {
  const _CourierTile({required this.courier});
  final Courier courier;

  @override
  Widget build(BuildContext context) {
    final tone = courier.status == CourierStatus.active ? StatusTone.positive : StatusTone.neutral;
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.md),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(border: Border.all(color: context.semantic.hairline), borderRadius: BorderRadius.circular(Insets.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(Insets.md)), alignment: Alignment.center, child: Icon(Icons.person_rounded, color: context.colors.onSurfaceVariant)),
              const SizedBox(width: Insets.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(courier.name, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: Insets.xs), Text(courier.phone, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant))])),
              StatusBadge(label: courier.status.label, tone: tone, dense: true),
            ],
          ),
          const SizedBox(height: Insets.md),
          Container(padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm), decoration: BoxDecoration(color: context.colors.surfaceContainerLowest, borderRadius: BorderRadius.circular(Insets.sm)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.two_wheeler_rounded, size: 16, color: context.colors.onSurfaceVariant), const SizedBox(width: Insets.xs), Text(courier.vehicle, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant))])),
        ],
      ),
    );
  }
}
