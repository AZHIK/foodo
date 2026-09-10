/// Wires connectivity changes to trigger automatic sync.
///
/// When the device transitions from offline to online, automatically calls
/// `syncService.syncNow()` to sync pending sales. This provider should be
/// watched once on app startup (via the router or shell) to arm the trigger.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_provider.dart';
import 'customer_api_provider.dart';
import 'finance_api_provider.dart';
import 'sync_status_provider.dart';

/// Arms the connectivity→sync trigger. Watch this once from the app shell.
final syncTriggerProvider = Provider<void>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final financeSyncService = ref.watch(financeSyncServiceProvider);
  final customerSyncService = ref.watch(customerSyncServiceProvider);

  // Track the last online state to detect offline→online transitions.
  var wasOnline = false;

  // Listen to connectivity changes.
  ref.listen(
    isOnlineProvider,
    (previous, next) {
      next.whenData((isOnline) {
        // Detect offline→online transition.
        if (!wasOnline && isOnline) {
          // Device went online: trigger sync. Customers MUST drain before
          // sales — a sale carrying a customer_id whose row hasn't reached
          // the server yet fails its FK insert and has to retry (see
          // `CustomerSyncService`'s doc comment).
          unawaited(() async {
            await customerSyncService.syncNow();
            await syncService.syncNow();
          }());
          financeSyncService.syncNow();
        }
        wasOnline = isOnline;
      });
    },
  );
});
