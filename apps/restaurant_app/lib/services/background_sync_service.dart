/// Background sync via workmanager.
///
/// `BackgroundSyncService` registers a periodic task that runs every ~15 minutes,
/// even when the app is in the background or the device is locked. The task
/// runs in its own isolate, so it must create its own database connection and
/// sync service (the foreground ProviderContainer is not available).
///
/// IMPORTANT: The callback dispatcher is a top-level function marked with
/// @pragma('vm:entry-point') so the workmanager background isolate can locate it.
library;

import 'package:workmanager/workmanager.dart';
import '../database/database_connection.dart';
import '../database/encryption_key_service.dart';
import '../database/app_database.dart';
import '../sync/sync_service.dart';
import '../sync/fake_sync_api.dart';

/// Registers the background sync task (call from main.dart after DB init).
void registerBackgroundSync() {
  Workmanager().initialize(callbackDispatcher);

  Workmanager().registerPeriodicTask(
    'pos-sync',
    'posSyncTask',
    frequency: const Duration(minutes: 15),
  );
}

/// Top-level callback dispatcher for the background isolate.
/// MUST be top-level and marked @pragma so workmanager can find it.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == 'posSyncTask') {
        // In the background isolate: create the key service, resolve key, open DB.
        final keyService = EncryptionKeyService();
        final encryptionKey = await keyService.getOrCreateKey();
        final database = AppDatabase(driftDatabaseConnection(encryptionKey));

        try {
          // Create a sync service with the fake API (real API comes in next task).
          final syncService = SyncService(
            db: database,
            api: FakeSyncApi(),
          );

          // Run sync.
          await syncService.syncNow();
          return true;
        } finally {
          await database.close();
        }
      }
      return false;
    } catch (e) {
      // Log error (in a real app, use Sentry or similar).
      print('Background sync failed: $e');
      return false;
    }
  });
}
