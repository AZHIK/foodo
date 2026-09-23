/// Bridges a dead backend session into Riverpod state.
 ///
 /// `TokenRefreshInterceptor` has no `ref` of its own, so it announces a
 /// rejected refresh on a static broadcast stream; this provider subscribes
 /// once (watched from the app root, like `syncTriggerProvider`) and drops
 /// the local session via `SessionNotifier.expireSession`, which routes to
 /// OTP login and raises the expiry alert through the guard.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_refresh_interceptor.dart';
import 'session_provider.dart';

/// Arms the refresh-rejection → sign-out bridge. Watch once from the app
/// shell; never read the value.
final sessionExpiryWatcherProvider = Provider<void>((ref) {
  final sub = TokenRefreshInterceptor.sessionExpired.listen((_) {
    // Fire-and-forget: the stream is synchronous-broadcast and listeners
    // must not await inside it.
    unawaited(
      Future(() => ref.read(sessionProvider.notifier).expireSession()),
    );
  });
  ref.onDispose(sub.cancel);
});
