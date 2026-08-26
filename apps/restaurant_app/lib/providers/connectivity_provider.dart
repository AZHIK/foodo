/// Riverpod providers for connectivity state.
///
/// `isOnlineProvider` exposes the device's online/offline status as a Riverpod
/// StreamProvider, triggering UI rebuilds when connectivity changes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// The connectivity service instance.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Stream of online/offline status: true = online, false = offline.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnlineStream;
});

/// Convenience: returns true if currently online (requires async context).
final isOnlineFutureProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnline();
});
