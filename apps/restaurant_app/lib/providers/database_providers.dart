/// Riverpod providers for database access.
///
/// `appDatabaseProvider` is the singleton instance of `AppDatabase`, created
/// once at app startup (in `main.dart`) with the decryption key and injected
/// via `ProviderScope(overrides: ...)` so all downstream providers can access it.
/// This keeps all other providers synchronous, avoiding the need for
/// `FutureProvider`/`AsyncValue` threading through 26+ existing provider files.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/local_profile_repository.dart';

/// The app's Drift database instance (singleton, created at startup).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnsupportedError(
    'appDatabaseProvider must be overridden with the actual AppDatabase instance '
    'in main.dart before any app code runs.',
  );
});

/// Repository for accessing local staff profiles and device config.
final localProfileRepositoryProvider = Provider<LocalProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalProfileRepository(db);
});
