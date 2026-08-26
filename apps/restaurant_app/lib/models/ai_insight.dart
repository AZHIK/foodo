import 'package:flutter/material.dart';

import '../widgets/data_page/status_badge.dart';

/// How much attention an insight is asking for.
enum InsightPriority {
  /// Something is going wrong now and costs money today.
  urgent('Act now', StatusTone.danger),

  /// Worth handling this week.
  advisory('Worth a look', StatusTone.warning),

  /// Good news, or a neutral observation.
  informational('FYI', StatusTone.info);

  const InsightPriority(this.label, this.tone);
  final String label;
  final StatusTone tone;
}

/// What kind of question the insight answers, which decides where "See detail"
/// sends the user.
enum InsightCategory {
  stock('Stock', Icons.inventory_2_outlined),
  waste('Waste', Icons.delete_sweep_outlined),
  sales('Sales', Icons.trending_up_rounded),
  staffing('Staffing', Icons.groups_outlined);

  const InsightCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// One generated observation about the business.
///
/// Deliberately carries its own evidence: an assistant that says "waste is up"
/// without saying which item, by how much, and over what window is not
/// something a manager can act on — or check.
@immutable
class AiInsight {
  const AiInsight({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    this.evidence = const [],
    this.actionLabel,
    this.actionRoute,
    this.actionParams = const {},
  });

  final String id;
  final String title;

  /// One or two sentences. Says what was observed and what it implies.
  final String body;

  final InsightCategory category;
  final InsightPriority priority;

  /// The numbers behind the claim, as short label/value pairs.
  final List<({String label, String value})> evidence;

  /// Optional deep link — "View item", "Open inventory".
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, String> actionParams;

  bool get hasAction => actionLabel != null && actionRoute != null;
}
