/// Monitors device connectivity and triggers sync when online.
///
/// `ConnectivityService` wraps `connectivity_plus`'s stream to detect
/// offline→online transitions and trigger `SyncService.syncNow()`.
library;

import 'package:connectivity_plus/connectivity_plus.dart';

/// Enum for device connectivity states.
enum ConnectivityStatus {
  online,
  offline,
}

/// Monitors and reports connectivity changes.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of connectivity changes: true = online, false = offline.
  Stream<bool> get isOnlineStream {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    });
  }

  /// Returns whether the device is currently online (cached state).
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }
}
