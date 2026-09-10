import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A receipt attached to an [OtherExpense]/[OtherIncome] entry.
///
/// [bytes] is populated for a receipt picked on this device and not yet (or
/// never) uploaded. [remoteId] is the server-assigned `FinanceAttachment.id`
/// once uploaded — a receipt pulled from another device's synced entry is
/// representable by [remoteId] alone, with [bytes] fetched lazily via
/// `FinanceApiService.fetchReceipt` only when actually viewed. [localPath]
/// is where the picked file was persisted on-device so it survives an app
/// restart before `FinanceSyncService` has uploaded it (see
/// `ExpenseEntries.localReceiptPath`).
@immutable
class FinanceAttachment {
  const FinanceAttachment({
    required this.name,
    this.bytes,
    this.remoteId,
    this.localPath,
  });

  final String name;
  final Uint8List? bytes;
  final String? remoteId;
  final String? localPath;
}
