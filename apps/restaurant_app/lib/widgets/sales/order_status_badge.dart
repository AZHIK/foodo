import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../data_page/status_badge.dart';

/// Maps the sales domain onto the shared badge tones.
///
/// The mapping lives here rather than in [StatusBadge] so the shared widget
/// stays free of any page's vocabulary.
extension OrderStatusTone on OrderStatus {
  StatusTone get tone => switch (this) {
    OrderStatus.paid => StatusTone.positive,
    OrderStatus.pending => StatusTone.warning,
    OrderStatus.refunded => StatusTone.danger,
    OrderStatus.voided => StatusTone.neutral,
  };

  IconData get badgeIcon => switch (this) {
    OrderStatus.paid => Icons.check_circle_rounded,
    OrderStatus.pending => Icons.schedule_rounded,
    OrderStatus.refunded => Icons.undo_rounded,
    OrderStatus.voided => Icons.block_rounded,
  };
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status, this.dense = false});

  final OrderStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: status.label,
    tone: status.tone,
    icon: status.badgeIcon,
    dense: dense,
  );
}
