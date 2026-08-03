import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper around [connectivity_plus] that exposes a Riverpod [StreamProvider]
/// of online/offline state.
///
/// Downstream providers can `ref.watch(connectivityProvider)` to react to
/// connectivity changes (e.g. pause/resume sync).
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});
