import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../data_page/status_badge.dart';

extension FulfillmentStatusTone on FulfillmentStatus {
  StatusTone get tone => switch (this) {
    FulfillmentStatus.new_ => StatusTone.info,
    FulfillmentStatus.preparing => StatusTone.warning,
    FulfillmentStatus.ready => StatusTone.positive,
    FulfillmentStatus.outForDelivery => StatusTone.positive,
    FulfillmentStatus.completed => StatusTone.neutral,
  };
}

class FulfillmentStatusBadge extends StatelessWidget {
  const FulfillmentStatusBadge({
    super.key,
    required this.status,
    this.dense = false,
  });

  final FulfillmentStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: status.label,
    tone: status.tone,
    icon: status.icon,
    dense: dense,
  );
}
