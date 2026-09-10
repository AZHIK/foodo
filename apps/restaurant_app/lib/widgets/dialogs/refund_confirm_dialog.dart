import 'package:flutter/material.dart';

import '../../theme/breakpoints.dart';

/// Confirms a refund and collects the reason in one step.
///
/// Returns the trimmed reason if confirmed, null if cancelled. The backend's
/// void/refund endpoint requires a non-empty reason
/// (`VoidRefundRequest.reason`), so the Refund button stays disabled until
/// one is typed — there is no way to confirm without it.
Future<String?> showRefundConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RefundConfirmDialog(title: title, message: message),
  );
}

class _RefundConfirmDialog extends StatefulWidget {
  const _RefundConfirmDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_RefundConfirmDialog> createState() => _RefundConfirmDialogState();
}

class _RefundConfirmDialogState extends State<_RefundConfirmDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: Insets.lg),
          TextField(
            controller: _reason,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why is this being refunded?',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_reason.text.trim()),
          child: const Text('Refund'),
        ),
      ],
    );
  }
}
