/// Bumped every time something writes to the local `CachedPermissions`
/// table — a plain database write has no Riverpod dependency of its own to
/// signal that on, so `currentUserPermissionsProvider`
/// (`permissions_provider.dart`) watches this counter purely as a manual
/// invalidation trigger, alongside the live token.
///
/// Without this, a write that isn't accompanied by a token/claims change —
/// exactly what `AuthNotifier.setPin` does for an invited staff member
/// finishing Set PIN, since no context-switch happens at that point — would
/// leave any already-resolved `currentUserPermissionsProvider` value stuck,
/// because none of its other watched dependencies ever changed again to
/// prompt a recompute.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionsCacheTickProvider = StateProvider<int>((ref) => 0);
