import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Watches connectivity so the offline queue can auto-flush when the device
/// comes back online. Reports a simple online/offline boolean.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// Fires whenever connectivity transitions, with the new online state.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
