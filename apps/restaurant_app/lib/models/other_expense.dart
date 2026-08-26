import 'package:flutter/material.dart';
import '../models/finance_attachment.dart';
import 'order.dart';

@immutable
class OtherExpense {
  const OtherExpense({
    required this.id,
    required this.date,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.paymentType,
    this.payee = '',
    this.note = '',
    this.receipt,
  });

  final String id;
  final DateTime date;
  final String categoryId;
  final String description;
  final double amount;
  final PaymentType paymentType;
  final String payee;
  final String note;
  final FinanceAttachment? receipt;

  OtherExpense copyWith({
    String? id,
    DateTime? date,
    String? categoryId,
    String? description,
    double? amount,
    PaymentType? paymentType,
    String? payee,
    String? note,
    FinanceAttachment? receipt,
    bool clearReceipt = false,
  }) {
    return OtherExpense(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      payee: payee ?? this.payee,
      note: note ?? this.note,
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OtherExpense && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
