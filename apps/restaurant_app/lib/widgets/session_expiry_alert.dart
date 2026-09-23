import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_strings.dart';
import '../providers/session_provider.dart';

/// Fires the "session expired" alert the moment a dead session is dropped.
///
/// Wraps the router's output (wired via `MaterialApp.router.builder`, so its
/// context can show dialogs above any screen) and watches
/// [sessionExpiredAlertProvider]: when it flips true — at the same instant
/// the guard routes to phone-number OTP login — a non-dismissible alert
/// explains why. The single button only closes the dialog; the user is
/// already on the login screen behind it. A local guard keeps a second
/// storm from stacking a second dialog.
class SessionExpiryAlert extends ConsumerStatefulWidget {
  const SessionExpiryAlert({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionExpiryAlert> createState() => _SessionExpiryAlertState();
}

class _SessionExpiryAlertState extends ConsumerState<SessionExpiryAlert> {
  var _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionExpiredAlertProvider, (previous, next) {
      if (next && !_dialogOpen) {
        _dialogOpen = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppStrings.sessionExpiredTitle),
            content: Text(AppStrings.sessionExpiredBody),
            actions: [
              FilledButton(
                onPressed: () {
                  ref.read(sessionExpiredAlertProvider.notifier).state = false;
                  Navigator.of(dialogContext).pop();
                },
                child: Text(AppStrings.sessionExpiredOk),
              ),
            ],
          ),
        ).then((_) => _dialogOpen = false);
      }
    });
    return widget.child;
  }
}
