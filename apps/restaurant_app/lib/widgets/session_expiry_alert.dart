import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_strings.dart';
import '../providers/session_provider.dart';
import '../utils/dialog_helper.dart';

/// Fires the "session expired" alert the moment a dead session is dropped.
///
/// Wraps the router's output (wired via `MaterialApp.router.builder`, so its
/// context can show dialogs above any screen) and watches
/// [sessionExpiredAlertProvider]: when it flips true — at the same instant
/// the guard routes to phone-number OTP login — a non-dismissible alert
/// explains why. The single button only closes the dialog; the user is
/// already on the login screen behind it. A local guard keeps a second
/// storm from stacking a second dialog.
///
/// Like `DeprovisionAlert`, presentation is deferred past the current frame
/// and retried (bounded) until a Navigator exists — the expiry can fire on
/// cold start before the router has built one, and showing immediately then
/// crashes with "Navigator operation requested with a context that does not
/// include a Navigator".
class SessionExpiryAlert extends ConsumerStatefulWidget {
  const SessionExpiryAlert({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionExpiryAlert> createState() => _SessionExpiryAlertState();
}

class _SessionExpiryAlertState extends ConsumerState<SessionExpiryAlert> {
  var _dialogOpen = false;

  /// Frames to keep retrying presentation while no Navigator exists yet.
  static const _maxRetries = 600;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionExpiredAlertProvider, (previous, next) {
      if (!next) return;
      _showWhenReady(_maxRetries);
    });
    return widget.child;
  }

  void _showWhenReady(int retriesLeft) {
    if (!mounted || _dialogOpen) return;
    if (!ref.read(sessionExpiredAlertProvider)) return;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _dialogOpen = false;
        return;
      }
      try {
        showAppDialog<bool>(
          context: context,
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
      } catch (_) {
        // No Navigator above us yet — retry on a later frame, bounded so a
        // truly Navigator-less tree can't spin forever.
        _dialogOpen = false;
        if (retriesLeft > 0) _showWhenReady(retriesLeft - 1);
      }
    });
  }
}
