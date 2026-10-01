import 'package:flutter/material.dart';

import '../models/finance_category.dart';

/// The canonical finance category taxonomy.
///
/// Ids are shared with the backend — see
/// `services/pos-service/app/models/finance.py::ExpenseCategory` and
/// `::IncomeCategory`. Keep the two lists in sync by hand; a category id
/// the backend doesn't know about fails sync validation.
///
/// This is a fixed taxonomy, not sample data: it carries no entries, only
/// the category definitions every entry references.
abstract final class FinanceCategories {
  static const expenseCategories = <FinanceCategory>[
    FinanceCategory(id: 'rent', label: 'Rent & lease', icon: Icons.home_work_outlined),
    FinanceCategory(id: 'utilities', label: 'Utilities', icon: Icons.bolt_outlined),
    FinanceCategory(id: 'salaries', label: 'Salaries', icon: Icons.badge_outlined),
    FinanceCategory(id: 'repairs', label: 'Repairs & maintenance', icon: Icons.build_outlined),
    FinanceCategory(id: 'supplies', label: 'Supplies', icon: Icons.inventory_2_outlined),
    FinanceCategory(id: 'marketing', label: 'Marketing', icon: Icons.campaign_outlined),
    FinanceCategory(id: 'insurance', label: 'Insurance', icon: Icons.shield_outlined),
    FinanceCategory(id: 'professional_fees', label: 'Professional fees', icon: Icons.gavel_outlined),
    FinanceCategory(id: 'other', label: 'Miscellaneous', icon: Icons.more_horiz_rounded),
  ];

  static const incomeCategories = <FinanceCategory>[
    FinanceCategory(id: 'catering', label: 'Catering & events', icon: Icons.event_outlined),
    FinanceCategory(id: 'grants', label: 'Grants & subsidies', icon: Icons.volunteer_activism_outlined),
    FinanceCategory(id: 'rebates', label: 'Rebates & refunds', icon: Icons.replay_outlined),
    FinanceCategory(id: 'space_rental', label: 'Space rental', icon: Icons.meeting_room_outlined),
    FinanceCategory(id: 'equipment_rental', label: 'Equipment rental', icon: Icons.construction_outlined),
    FinanceCategory(id: 'other', label: 'Miscellaneous', icon: Icons.more_horiz_rounded),
  ];

  static FinanceCategory? expenseById(String id) {
    for (final category in expenseCategories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static String expenseLabel(String id) => expenseById(id)?.label ?? id;

  static FinanceCategory? incomeById(String id) {
    for (final category in incomeCategories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static String incomeLabel(String id) => incomeById(id)?.label ?? id;
}
