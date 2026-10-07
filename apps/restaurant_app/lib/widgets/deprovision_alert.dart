import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_provision_guard_provider.dart';
import '../utils/dialog_helper.dart';

/// Explains an automatic sign-out caused by a remote deletion.
///
/// Wraps the router's output next to `SessionExpiryAlert`: when
/// [deprovisionAlertProvider] is raised — at the same instant the guard
/// routes to phone-number OTP login — a non-dismissible dialog tells the
/// user whether their business was deleted (local data wiped) or only their
/// store was removed (device unprovisioned, sign in again to pick another
/// store). The button only closes the dialog; routing already happened.
///
/// The guard can fire on cold start before the router has built a Navigator,
/// so presentation is deferred past the current frame and retried (bounded)
/// until a Navigator exists — showing immediately here crashes with
/// "Navigator operation requested with a context that does not include a
/// Navigator".
class DeprovisionAlert extends ConsumerStatefulWidget {
  const DeprovisionAlert({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeprovisionAlert> createState() => _DeprovisionAlertState();
}

class _DeprovisionAlertState extends ConsumerState<DeprovisionAlert> {
  var _dialogOpen = false;

  /// Frames to keep retrying presentation while no Navigator exists yet.
  static const _maxRetries = 600;

  @override
  Widget build(BuildContext context) {
    ref.listen<DeprovisionEvent?>(
      deprovisionAlertProvider,
      (previous, next) {
        if (next == null) return;
        _showWhenReady(_maxRetries);
      },
    );
    return widget.child;
  }

  void _showWhenReady(int retriesLeft) {
    if (!mounted || _dialogOpen) return;
    final event = ref.read(deprovisionAlertProvider);
    if (event == null) return;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _dialogOpen = false;
        return;
      }
      try {
        final isBusiness = event == DeprovisionEvent.businessDeleted;
        showAppDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              isBusiness ? 'Business removed' : 'Store removed',
            ),
            content: Text(
              isBusiness
                  ? 'This business was deleted online. You have been signed '
                      'out and local data on this device was cleared.'
                  : 'Your store was deleted online. You have been signed out. '
                      'Sign in again to continue with another store.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  ref.read(deprovisionAlertProvider.notifier).state = null;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) => _dialogOpen = false);
      } catch (_) {
        // No Navigator above us yet (cold-start guard fired before the
        // router built one) — retry on a later frame, bounded so a
        // truly Navigator-less tree can't spin forever.
        _dialogOpen = false;
        if (retriesLeft > 0) _showWhenReady(retriesLeft - 1);
      }
    });
  }
}
