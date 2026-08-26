import 'package:flutter/material.dart';

import '../widgets/data_page/status_badge.dart';

/// One thing that happened, for a timeline.
///
/// Generic on purpose: a staff member's audit log today, an order's status
/// history tomorrow. The timeline widget renders these and knows nothing about
/// where they came from.
@immutable
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.at,
    required this.title,
    required this.icon,
    this.detail,
    this.tone = StatusTone.neutral,
  });

  final String id;
  final DateTime at;

  /// What happened, in one line: "Processed order #1042".
  final String title;

  /// Supporting context: an amount, a note, an affected item.
  final String? detail;

  final IconData icon;

  /// Tints the timeline dot. Neutral for routine events, so the ones that
  /// carry colour are the ones actually worth spotting.
  final StatusTone tone;
}
