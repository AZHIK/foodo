import 'package:flutter/material.dart';
import '../models/finance_category.dart';
import '../models/order.dart';
import '../models/other_expense.dart';
import '../models/other_income.dart';

abstract final class MockFinance {
  static const expenseCategories = <FinanceCategory>[
    FinanceCategory(id: 'rent', label: 'Rent & lease', icon: Icons.home_work_outlined),
    FinanceCategory(id: 'utilities', label: 'Utilities', icon: Icons.bolt_outlined),
    FinanceCategory(id: 'repairs', label: 'Repairs & maintenance', icon: Icons.build_outlined),
    FinanceCategory(id: 'marketing', label: 'Marketing', icon: Icons.campaign_outlined),
    FinanceCategory(id: 'insurance', label: 'Insurance', icon: Icons.shield_outlined),
    FinanceCategory(id: 'professional', label: 'Professional fees', icon: Icons.gavel_outlined),
    FinanceCategory(id: 'misc-expense', label: 'Miscellaneous', icon: Icons.more_horiz_rounded),
  ];

  static const incomeCategories = <FinanceCategory>[
    FinanceCategory(id: 'catering', label: 'Catering & events', icon: Icons.event_outlined),
    FinanceCategory(id: 'grants', label: 'Grants & subsidies', icon: Icons.volunteer_activism_outlined),
    FinanceCategory(id: 'rebates', label: 'Rebates & refunds', icon: Icons.replay_outlined),
    FinanceCategory(id: 'rental-income', label: 'Space rental', icon: Icons.meeting_room_outlined),
    FinanceCategory(id: 'misc-income', label: 'Miscellaneous', icon: Icons.more_horiz_rounded),
  ];

  static FinanceCategory? expenseCategoryById(String id) {
    for (final category in expenseCategories) { if (category.id == id) return category; }
    return null;
  }
  static String expenseCategoryLabel(String id) => expenseCategoryById(id)?.label ?? id;
  static FinanceCategory? incomeCategoryById(String id) {
    for (final category in incomeCategories) { if (category.id == id) return category; }
    return null;
  }
  static String incomeCategoryLabel(String id) => incomeCategoryById(id)?.label ?? id;

  static final List<OtherExpense> expenses = <OtherExpense>[
    _expense('exp-01', DateTime.now().subtract(Duration(days: 2)), 'rent', 'Monthly unit rent — June', 3200.00, PaymentType.card, payee: 'Fenwick Holdings'),
    _expense('exp-02', DateTime.now().subtract(Duration(days: 5)), 'utilities', 'Electricity & gas', 640.50, PaymentType.card, payee: 'City Power & Gas'),
    _expense('exp-03', DateTime.now().subtract(Duration(days: 1)), 'repairs', 'Walk-in fridge compressor repair', 480.00, PaymentType.cash, payee: 'ColdFix Services'),
    _expense('exp-04', DateTime.now().subtract(Duration(days: 10)), 'marketing', 'Local paper ad, two weeks', 220.00, PaymentType.card, payee: 'Harbor Weekly'),
    _expense('exp-05', DateTime.now().subtract(Duration(days: 30)), 'insurance', 'Liability insurance — quarterly', 890.00, PaymentType.card, payee: 'Guardian Mutual'),
    _expense('exp-06', DateTime.now().subtract(Duration(days: 15)), 'professional', 'Bookkeeping, May', 350.00, PaymentType.card, payee: 'Lin & Associates'),
    _expense('exp-07', DateTime.now().subtract(Duration(days: 3)), 'misc-expense', 'Parking permits renewal', 90.00, PaymentType.cash, payee: 'City Council'),
    _expense('exp-08', DateTime.now().subtract(Duration(days: 22)), 'repairs', 'Door hinge repair', 125.00, PaymentType.cash, payee: 'Local Hardware'),
  ];

  static final List<OtherIncome> incomes = <OtherIncome>[
    _income('inc-01', DateTime.now().subtract(Duration(days: 4)), 'catering', 'Corporate lunch catering — Alder & Finch', 1450.00, PaymentType.card, source: 'Alder & Finch Law'),
    _income('inc-02', DateTime.now().subtract(Duration(days: 12)), 'grants', 'Small business energy grant', 2000.00, PaymentType.card, source: 'City Economic Development'),
    _income('inc-03', DateTime.now().subtract(Duration(days: 8)), 'rental-income', 'Private room hire — birthday party', 300.00, PaymentType.cash, source: 'M. Alvarez'),
    _income('inc-04', DateTime.now().subtract(Duration(days: 20)), 'rebates', 'Supplier volume rebate', 175.00, PaymentType.card, source: 'Fenwick Farm'),
    _income('inc-05', DateTime.now().subtract(Duration(days: 1)), 'catering', 'Wedding catering deposit', 900.00, PaymentType.mobile, source: 'J. & R. Whitfield'),
    _income('inc-06', DateTime.now().subtract(Duration(days: 25)), 'misc-income', 'Deposit refund from cancelled event', 250.00, PaymentType.card, source: 'Event Planner Co.'),
  ];

  static OtherExpense _expense(String id, DateTime date, String categoryId, String description, double amount, PaymentType paymentType, {String payee = ''}) {
    return OtherExpense(id: id, date: date, categoryId: categoryId, description: description, amount: amount, paymentType: paymentType, payee: payee);
  }
  static OtherIncome _income(String id, DateTime date, String categoryId, String description, double amount, PaymentType paymentType, {String source = ''}) {
    return OtherIncome(id: id, date: date, categoryId: categoryId, description: description, amount: amount, paymentType: paymentType, source: source);
  }
}
