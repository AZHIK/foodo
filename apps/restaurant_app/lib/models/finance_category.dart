import 'package:flutter/material.dart';

@immutable
class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}
