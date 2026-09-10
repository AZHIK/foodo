import 'package:flutter/material.dart';
import '../models/finance_attachment.dart';
import 'order.dart';

@immutable
class OtherIncome {
  const OtherIncome({
    required this.id,
    required this.date,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.paymentType,
    this.source = '',
    this.note = '',
    this.receipt,
    this.serverId,
    this.syncStatus = 'synced',
  });

  final String id;
  final DateTime date;
  final String categoryId;
  final String description;
  final double amount;
  final PaymentType paymentType;
  final String source;
  final String note;
  final FinanceAttachment? receipt;

  /// Server-assigned `OtherIncome.id` once this entry has synced. Null for
  /// a demo-mode row or one still in the outbox.
  final String? serverId;

  /// `pending` | `syncing` | `failed` | `synced`. See `OtherExpense.syncStatus`.
  final String syncStatus;

  OtherIncome copyWith({
    String? id,
    DateTime? date,
    String? categoryId,
    String? description,
    double? amount,
    PaymentType? paymentType,
    String? source,
    String? note,
    FinanceAttachment? receipt,
    bool clearReceipt = false,
    String? serverId,
    String? syncStatus,
  }) {
    return OtherIncome(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      source: source ?? this.source,
      note: note ?? this.note,
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OtherIncome && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
