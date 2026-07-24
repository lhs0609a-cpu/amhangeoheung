import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity service that monitors network status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream that emits true when online, false when offline
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      // Consider online if any connection type is available (mobile, wifi, ethernet, etc.)
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    });
  }

  /// Check current connectivity status
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

/// Riverpod provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// StreamProvider that emits connectivity status (true = online, false = offline)
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
